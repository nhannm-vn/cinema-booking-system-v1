// supabase/functions/create-staff/index.ts
// References: TECH_STACK.md Section 8.3 & BUSINESS_RULES.md Section 12
import { createClient } from 'jsr:@supabase/supabase-js@2';

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
    const authHeader = req.headers.get('Authorization') ?? '';
    const supabaseCaller = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Xác thực người gọi
    const { data: { user: callerUser }, error: userError } = await supabaseCaller.auth.getUser();
    if (userError || !callerUser) {
      return new Response(JSON.stringify({ error: 'UNAUTHORIZED' }), { status: 401 });
    }

    const { data: callerProfile, error: profileError } = await supabaseCaller
      .from('profiles')
      .select('role, cinema_id, is_locked')
      .eq('id', callerUser.id)
      .single();

    if (profileError || !callerProfile || callerProfile.is_locked) {
      return new Response(JSON.stringify({ error: 'FORBIDDEN' }), { status: 403 });
    }

    const { email, password, full_name, phone, role, cinema_id } = await req.json();

    // Phân quyền tạo
    let assignedRole = role || 'staff';
    let assignedCinema = cinema_id;

    if (callerProfile.role === 'manager') {
      // Manager chỉ tạo được Staff và chỉ cho rạp của chính mình
      assignedRole = 'staff';
      assignedCinema = callerProfile.cinema_id;
    } else if (callerProfile.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'FORBIDDEN' }), { status: 403 });
    }

    // Dùng service role client để tạo user trong Auth
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const { data: newUserData, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name },
    });

    if (createError) {
      return new Response(JSON.stringify({ error: createError.message }), { status: 400 });
    }

    const newUserId = newUserData.user.id;

    // Cập nhật profile
    const { error: updateProfileError } = await supabaseAdmin
      .from('profiles')
      .update({
        full_name,
        phone,
        role: assignedRole,
        cinema_id: assignedCinema,
        is_locked: false,
      })
      .eq('id', newUserId);

    if (updateProfileError) {
      return new Response(JSON.stringify({ error: updateProfileError.message }), { status: 500 });
    }

    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: newUserId,
          email,
          full_name,
          role: assignedRole,
          cinema_id: assignedCinema,
        },
      }),
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
