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
      const authHeader = req.headers.get('Authorization') || '';
      const providedKey = authHeader.replace(/^Apikey\s+/i, '').trim();
      if (providedKey !== apiKey) {
        return new Response(JSON.stringify({ error: 'UNAUTHORIZED' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }

    const payload = await req.json().catch(() => ({}));
    const transferType = payload.transferType || 'in';
    if (transferType !== 'in') {
      return new Response(JSON.stringify({ success: true, message: 'IGNORED_TRANSFER_TYPE' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const content = String(payload.content || payload.des || payload.booking_code || '');
    const transferAmount = Number(payload.transferAmount || payload.amount || 0);
    const sepayTransactionId = String(payload.id || payload.referenceCode || Date.now());

    // 2. Find booking code from transfer content
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Look for pending payments or matching bookings
    let bookingCode = payload.booking_code;
    let txnRef = payload.txn_ref;

    if (!bookingCode) {
      // Find 8-char alphanumeric code in content
      const matches = content.toUpperCase().match(/[A-Z0-9]{8}/g);
      if (matches && matches.length > 0) {
        for (const candidate of matches) {
          const { data } = await supabaseAdmin
            .from('bookings')
            .select('code')
            .eq('code', candidate)
            .single();
          if (data) {
            bookingCode = data.code;
            break;
          }
        }
      }
    }

    if (!bookingCode) {
      return new Response(JSON.stringify({ error: 'BOOKING_CODE_NOT_FOUND_IN_CONTENT' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
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
