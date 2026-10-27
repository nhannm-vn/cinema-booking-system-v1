// supabase/functions/vnpay-return/index.ts
// References: TECH_STACK.md Section 8.2
import { createClient } from 'jsr:@supabase/supabase-js@2';

const secret = Deno.env.get('VNPAY_HASH_SECRET') || 'VNPAY_SANDBOX_SECRET_KEY';

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
  try {
    const url = new URL(req.url);
    const params: Record<string, string> = {};
    for (const [key, value] of url.searchParams.entries()) {
      params[key] = value;
    }

    const secureHash = params['vnp_SecureHash'];
    delete params['vnp_SecureHash'];
    delete params['vnp_SecureHashType'];

    const sortedQuery = Object.keys(params)
      .sort()
      .map((k) => `${k}=${encodeURIComponent(params[k]).replace(/%20/g, '+')}`)
      .join('&');

    const expectedHash = await hmacSha512(secret, sortedQuery);
    const isSignatureValid = expectedHash.toLowerCase() === secureHash?.toLowerCase();

    if (!isSignatureValid) {
      return new Response('<html><body><h1>Chu ky khong hop le</h1></body></html>', {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
        status: 400,
      });
    }

    const responseCode = params['vnp_ResponseCode'];
    const txnRef = params['vnp_TxnRef'];
    const vnpTransactionNo = params['vnp_TransactionNo'] || '';
    const amount = Math.floor(parseInt(params['vnp_Amount'] || '0', 10) / 100);

    // Dùng service role client để gọi confirm_payment
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Lấy booking code từ payment
    const { data: payment } = await supabaseAdmin
      .from('payments')
      .select('booking_code')
      .eq('txn_ref', txnRef)
      .single();

    if (!payment) {
      return new Response('<html><body><h1>Giao dich khong ton tai</h1></body></html>', {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
        status: 404,
      });
    }

    if (responseCode === '00') {
      // Gọi RPC confirm_payment
      const { error: rpcError } = await supabaseAdmin.rpc('confirm_payment', {
        p_booking_code: payment.booking_code,
        p_txn_ref: txnRef,
        p_vnp_transaction_no: vnpTransactionNo,
        p_amount: amount,
      });

      if (rpcError) {
        return new Response(`<html><body><h1>Loi xac nhan: ${rpcError.message}</h1></body></html>`, {
          headers: { 'Content-Type': 'text/html; charset=utf-8' },
          status: 400,
        });
      }

      return new Response(
        `<html><body><script>window.location.href="cinemaapp://payment-success?code=${payment.booking_code}";</script><h1>Thanh toan thanh cong! Dang chuyen huong...</h1></body></html>`,
        { headers: { 'Content-Type': 'text/html; charset=utf-8' } }
      );
    } else {
      await supabaseAdmin.from('payments').update({
        status: 'failed',
        response_code: responseCode,
      }).eq('txn_ref', txnRef);

      return new Response(
        `<html><body><script>window.location.href="cinemaapp://payment-failed?code=${responseCode}";</script><h1>Thanh toan that bai (Ma: ${responseCode}).</h1></body></html>`,
        { headers: { 'Content-Type': 'text/html; charset=utf-8' } }
      );
    }
  } catch (err: any) {
    return new Response(`<html><body><h1>Loi he thong: ${err.message}</h1></body></html>`, {
      headers: { 'Content-Type': 'text/html; charset=utf-8' },
      status: 500,
    });
  }
});
