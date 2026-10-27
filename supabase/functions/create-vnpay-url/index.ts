// supabase/functions/create-vnpay-url/index.ts
// References: TECH_STACK.md Section 8.1
import { createClient } from 'jsr:@supabase/supabase-js@2';

const secret = Deno.env.get('VNPAY_HASH_SECRET') || 'VNPAY_SANDBOX_SECRET_KEY';
const tmnCode = Deno.env.get('VNPAY_TMN_CODE') || 'VNPAY_TMN_CODE';
const vnpUrl = Deno.env.get('VNPAY_URL') || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

async function hmacSha512(key: string, data: string): Promise<string> {
  const enc = new TextEncoder();
  const k = await crypto.subtle.importKey(
    'raw',
    enc.encode(key),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', k, enc.encode(data));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

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

    const { booking_code, txn_ref, return_url, ip } = await req.json();

    if (!booking_code || !txn_ref) {
      return new Response(JSON.stringify({ error: 'MISSING_PARAMS' }), { status: 400 });
    }

    const { data: booking, error } = await supabase
      .from('bookings')
      .select('code, price_snapshot, movie_title, status, hold_until')
      .eq('code', booking_code)
      .single();

    if (error || !booking) {
      return new Response(JSON.stringify({ error: 'BOOKING_NOT_FOUND' }), { status: 404 });
    }

    if (booking.status !== 'holding') {
      return new Response(JSON.stringify({ error: 'BOOKING_NOT_HOLDING' }), { status: 400 });
    }

    const totalAmount = booking.price_snapshot?.total ?? 0;
    const now = new Date();
    const createDate = now.toISOString().replace(/\D/g, '').slice(0, 14);

    const params: Record<string, string> = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: tmnCode,
      vnp_Amount: String(totalAmount * 100),
      vnp_CurrCode: 'VND',
      vnp_TxnRef: txn_ref,
      vnp_OrderInfo: `Thanh toan ve ${booking.code}`,
      vnp_OrderType: 'other',
      vnp_Locale: 'vn',
      vnp_ReturnUrl: return_url || 'https://cinema-booking.example.com/vnpay-return',
      vnp_IpAddr: ip || '127.0.0.1',
      vnp_CreateDate: createDate,
    };

    const query = Object.keys(params)
      .sort()
      .map((k) => `${k}=${encodeURIComponent(params[k]).replace(/%20/g, '+')}`)
      .join('&');

    const hash = await hmacSha512(secret, query);
    const paymentUrl = `${vnpUrl}?${query}&vnp_SecureHash=${hash}`;

    // Dùng service role client để upsert payment record (vượt qua RLS payments_no_direct_insert)
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
      JSON.stringify({ url: paymentUrl, txn_ref }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
