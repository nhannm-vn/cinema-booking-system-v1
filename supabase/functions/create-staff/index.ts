// supabase/functions/create-staff/index.ts
// References: TECH_STACK.md Section 8.3 & BUSINESS_RULES.md Section 12
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const supabaseCaller = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // 1. Xác thực người gọi
    const { data: { user: callerUser }, error: userError } = await supabaseCaller.auth.getUser();
    if (userError || !callerUser) {
      return new Response(
        JSON.stringify({ error: 'UNAUTHORIZED: Vui lòng đăng nhập lại để thực hiện' }),
        { status: 401, headers: corsHeaders }
      );
    }

    const { data: callerProfile, error: profileError } = await supabaseCaller
      .from('profiles')
      .select('role, cinema_id, is_locked')
      .eq('id', callerUser.id)
      .single();

    if (profileError || !callerProfile || callerProfile.is_locked) {
      return new Response(
        JSON.stringify({ error: 'FORBIDDEN: Tài khoản không có quyền hoặc đã bị khóa' }),
        { status: 403, headers: corsHeaders }
      );
    }

    const { email, password, full_name, phone, role, cinema_id } = await req.json();

    if (!email || !password || password.length < 6) {
      return new Response(
        JSON.stringify({ error: 'Vui lòng cung cấp email và mật khẩu (tối thiểu 6 ký tự)' }),
        { status: 400, headers: corsHeaders }
      );
    }

    // 2. Phân quyền tạo vai trò
    let assignedRole = role === 'manager' ? 'manager' : 'staff';
    let assignedCinema = cinema_id;

    if (callerProfile.role === 'manager') {
      // Manager chỉ tạo được Staff cho rạp của mình
      assignedRole = 'staff';
      assignedCinema = callerProfile.cinema_id;
    } else if (callerProfile.role === 'admin') {
      // Admin có thể tạo Manager hoặc Staff cho rạp bất kỳ
      assignedRole = role === 'manager' ? 'manager' : 'staff';
      assignedCinema = cinema_id;
    } else {
      return new Response(
        JSON.stringify({ error: 'FORBIDDEN: Chỉ Admin hoặc Manager mới có quyền tạo tài khoản nhân sự' }),
        { status: 403, headers: corsHeaders }
      );
    }

    if (!assignedCinema) {
      return new Response(
        JSON.stringify({ error: 'Vui lòng chọn rạp công tác cho nhân sự' }),
        { status: 400, headers: corsHeaders }
      );
    }

    // 3. Dùng service role client để tạo user trong Auth
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const { data: newUserData, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: full_name || '', phone: phone || null },
      app_metadata: { role: assignedRole, cinema_id: assignedCinema },
    });

    if (createError) {
      let msg = createError.message;
      if (msg.includes('already been registered') || msg.includes('unique')) {
        msg = `Email ${email} đã được đăng ký trong hệ thống`;
      }
      return new Response(
        JSON.stringify({ error: msg }),
        { status: 400, headers: corsHeaders }
      );
    }

    const newUserId = newUserData.user.id;

    // 4. Cập nhật profile (sử dụng upsert để luôn đảm bảo role và cinema_id chính xác)
    const { error: updateProfileError } = await supabaseAdmin
      .from('profiles')
      .upsert({
        id: newUserId,
        full_name: full_name || '',
        phone: phone || null,
        role: assignedRole,
        cinema_id: assignedCinema,
        is_locked: false,
        updated_at: new Date().toISOString(),
      });

    if (updateProfileError) {
      return new Response(
        JSON.stringify({ error: `Lỗi cập nhật hồ sơ: ${updateProfileError.message}` }),
        { status: 500, headers: corsHeaders }
      );
    }

    // 5. Ghi nhật ký thao tác (Audit Log)
    try {
      await supabaseAdmin.from('audit_logs').insert({
        actor_id: callerUser.id,
        actor_role: callerProfile.role,
        cinema_id: assignedCinema,
        action: 'createStaff',
        target_type: 'profile',
        target_id: newUserId,
        reason: `Tạo tài khoản ${assignedRole.toUpperCase()} (${email}) cho rạp ${assignedCinema}`,
        new_data: {
          email,
          full_name,
          phone,
          role: assignedRole,
          cinema_id: assignedCinema,
        },
      });
    } catch (_) {
      // Non-blocking
    }

    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: newUserId,
          email,
          full_name: full_name || '',
          phone: phone || null,
          role: assignedRole,
          cinema_id: assignedCinema,
        },
      }),
      { status: 200, headers: corsHeaders }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || 'Lỗi xử lý server' }),
      { status: 500, headers: corsHeaders }
    );
  }
});
