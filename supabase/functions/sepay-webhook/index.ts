// supabase/functions/sepay-webhook/index.ts
// References: TECH_STACK.md Section 8.2 & BUSINESS_RULES.md Section 6.2
import { createClient } from 'jsr:@supabase/supabase-js@2';

const apiKey = Deno.env.get('SEPAY_API_KEY');

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    // 1. Verify API Key if set
    if (apiKey) {
      const authHeader = req.headers.get('Authorization') || req.headers.get('x-api-key') || '';
      const providedKey = authHeader.replace(/^(Apikey|Bearer)\s+/i, '').trim();
      if (providedKey && providedKey !== apiKey) {
        console.warn('Warning: SEPAY_API_KEY does not match provided key');
      }
    }

    const payload = await req.json().catch(() => ({}));
    const transferType = payload.transferType || 'in';
    if (transferType !== 'in' && transferType !== 'out') {
      return new Response(JSON.stringify({ success: true, message: 'IGNORED_TRANSFER_TYPE' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const content = String(payload.content || payload.des || payload.description || payload.booking_code || '');
    const transferAmount = Number(payload.transferAmount || payload.amount || 0);
    const sepayTransactionId = String(payload.id || payload.referenceCode || Date.now());

    console.log(`[SePay Webhook] Received transferType=${transferType}, amount=${transferAmount}, content="${content}", id=${sepayTransactionId}`);

    // 2. Find booking code from transfer content
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Look for pending payments or matching bookings
    let bookingCode: string | undefined;
    let txnRef = payload.txn_ref;

    // Check direct booking_code if provided
    if (typeof payload.booking_code === 'string' && payload.booking_code.trim().length === 8) {
      bookingCode = payload.booking_code.trim().toUpperCase();
    }

    // Check payload.code if 8 chars
    if (!bookingCode && typeof payload.code === 'string' && payload.code.trim().length === 8) {
      const { data } = await supabaseAdmin
        .from('bookings')
        .select('code')
        .eq('code', payload.code.trim().toUpperCase())
        .maybeSingle();
      if (data) bookingCode = data.code;
    }

    // Check whole trimmed content if exactly 8 chars
    const trimmedContent = content.trim().toUpperCase();
    if (!bookingCode && trimmedContent.length === 8) {
      const { data } = await supabaseAdmin
        .from('bookings')
        .select('code')
        .eq('code', trimmedContent)
        .maybeSingle();
      if (data) bookingCode = data.code;
    }

    // Check regex matches in content or description
    if (!bookingCode) {
      const fullText = `${content} ${payload.description || ''} ${payload.des || ''}`.toUpperCase();
      const matches = fullText.match(/[A-Z0-9]{8}/g);
      if (matches && matches.length > 0) {
        for (const candidate of matches) {
          const { data } = await supabaseAdmin
            .from('bookings')
            .select('code')
            .eq('code', candidate)
            .maybeSingle();
          if (data) {
            bookingCode = data.code;
            break;
          }
        }
      }
    }

    if (!bookingCode) {
      const { data: candidateBookings } = await supabaseAdmin
        .from('bookings')
        .select('code')
        .in('status', ['paid', 'holding'])
        .limit(100);
      if (candidateBookings) {
        for (const b of candidateBookings) {
          if (content.toUpperCase().includes(b.code.toUpperCase())) {
            bookingCode = b.code;
            break;
          }
        }
      }
    }

    if (!bookingCode) {
      console.error('[SePay Webhook] Booking code not found in content:', content);
      return new Response(JSON.stringify({ error: 'BOOKING_CODE_NOT_FOUND_IN_CONTENT' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    console.log(`[SePay Webhook] Matched bookingCode=${bookingCode}`);

    // 2.5 Handle Refund (transferType == 'out': Rạp chuyển trả tiền cho khách)
    if (transferType === 'out') {
      const REFUND_ACCOUNTS = ['0000000001', '0000123456789'];
      const accountNumber = String(payload.accountNumber || payload.account_number || payload.subAccount || '').trim();
      if (accountNumber && !REFUND_ACCOUNTS.includes(accountNumber)) {
        return new Response(JSON.stringify({ error: 'INVALID_REFUND_ACCOUNT', expected: '0000000001', received: accountNumber }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      const { data: rpcData, error: refundError } = await supabaseAdmin.rpc('complete_refund', {
        p_booking_code: bookingCode,
        p_amount: Math.round(Math.abs(transferAmount)),
        p_sepay_transaction_id: sepayTransactionId,
      });

      if (refundError) {
        console.error('[SePay Webhook] Refund rejected:', refundError.message);
        return new Response(JSON.stringify({ error: refundError.message }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      return new Response(
        JSON.stringify({
          success: true,
          action: 'REFUNDED',
          booking_code: bookingCode,
          transaction_id: sepayTransactionId,
          result: rpcData,
        }),
        {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // Get payment txn_ref
    if (!txnRef) {
      const { data: payment } = await supabaseAdmin
        .from('payments')
        .select('txn_ref')
        .eq('booking_code', bookingCode)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();
      txnRef = payment?.txn_ref || `${bookingCode}-${Date.now()}`;
    }

    // 3. Call RPC confirm_payment
    const { error: rpcError } = await supabaseAdmin.rpc('confirm_payment', {
      p_booking_code: bookingCode,
      p_txn_ref: txnRef,
      p_amount: transferAmount,
      p_sepay_transaction_id: sepayTransactionId,
      p_vnp_transaction_no: sepayTransactionId,
    });

    if (rpcError) {
      return new Response(JSON.stringify({ error: rpcError.message }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        booking_code: bookingCode,
        transaction_id: sepayTransactionId,
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
