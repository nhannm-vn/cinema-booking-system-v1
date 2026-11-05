// supabase/functions/smooth-endpoint/index.ts
// Handles SePay webhooks when configured as smooth-endpoint
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
      const { data: b } = await supabaseAdmin
        .from('bookings')
        .select('*')
        .eq('code', bookingCode)
        .single();

      if (!b) {
        return new Response(JSON.stringify({ error: 'BOOKING_NOT_FOUND' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      if (b.status !== 'cancelled') {
        // Xóa ghế đã giữ
        await supabaseAdmin.from('seats').delete().eq('booking_code', bookingCode);

        // Giảm sold_seats
        const seatCount = Array.isArray(b.seats) ? b.seats.length : 0;
        if (seatCount > 0 && b.showtime_id) {
          const { data: st } = await supabaseAdmin
            .from('showtimes')
            .select('sold_seats')
            .eq('id', b.showtime_id)
            .single();
          if (st) {
            await supabaseAdmin
              .from('showtimes')
              .update({ sold_seats: Math.max(0, (st.sold_seats || 0) - seatCount) })
              .eq('id', b.showtime_id);
          }
        }

        // Cập nhật booking status = 'cancelled'
        await supabaseAdmin.from('bookings').update({
          status: 'cancelled',
          food_status: b.food_status === 'pending' ? 'cancelled' : b.food_status,
          cancel_reason: `Hoàn tiền SePay từ tài khoản rạp 0000000001: ${sepayTransactionId}`,
          cancelled_at: new Date().toISOString(),
          sepay_transaction_id: sepayTransactionId,
        }).eq('code', bookingCode);

        // Tạo thông báo
        if (b.user_id) {
          await supabaseAdmin.from('notifications').insert({
            user_id: b.user_id,
            type: 'bookingRefunded',
            title: 'Đã hoàn vé xem phim',
            body: `Vé ${bookingCode} đã được chuyển hoàn tiền 100% (+${transferAmount || b.price_snapshot?.total || 0}đ) từ tài khoản rạp 0000000001 (CINEMA BOOKING SYSTEM) về tài khoản khách hàng.`,
            booking_code: bookingCode,
          });
        }
      }

      return new Response(
        JSON.stringify({
          success: true,
          action: 'REFUNDED',
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
