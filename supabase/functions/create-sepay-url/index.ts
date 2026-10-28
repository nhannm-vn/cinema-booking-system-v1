// supabase/functions/create-sepay-url/index.ts
// References: TECH_STACK.md Section 8.1 & BUSINESS_RULES.md Section 6.2
import { createClient } from 'jsr:@supabase/supabase-js@2';

const bank = Deno.env.get('SEPAY_BANK') || 'MBBank';
const accountNo = Deno.env.get('SEPAY_ACCOUNT_NO') || '0000123456789';
const accountName = Deno.env.get('SEPAY_ACCOUNT_NAME') || 'CINEMA BOOKING SYSTEM';

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
    const auth = req.headers.get('Authorization') ?? '';
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: auth } } }
    );

    const { booking_code, txn_ref } = await req.json();

    if (!booking_code || !txn_ref) {
      return new Response(JSON.stringify({ error: 'MISSING_PARAMS' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    const { data: booking, error } = await supabase
      .from('bookings')
      .select('code, price_snapshot, movie_title, status, hold_until')
      .eq('code', booking_code)
      .single();

    if (error || !booking) {
      return new Response(JSON.stringify({ error: 'BOOKING_NOT_FOUND' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    if (booking.status !== 'holding') {
      return new Response(JSON.stringify({ error: 'BOOKING_NOT_HOLDING' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    const totalAmount = booking.price_snapshot?.total ?? 0;
    // SePay standard VietQR format
    const qrUrl = `https://qr.sepay.vn/img?bank=${encodeURIComponent(bank)}&acc=${encodeURIComponent(accountNo)}&template=compact&amount=${totalAmount}&des=${encodeURIComponent(booking.code)}`;

    // Dùng service role client để upsert payment record
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    await supabaseAdmin.from('payments').upsert({
      txn_ref: txn_ref,
      booking_code: booking.code,
      amount: totalAmount,
      status: 'pending',
    });

    return new Response(
      JSON.stringify({
        url: qrUrl,
        qr_url: qrUrl,
        payment_url: qrUrl,
        bank,
        account_no: accountNo,
        account_name: accountName,
        amount: totalAmount,
        content: booking.code,
        txn_ref,
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
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  }
});
