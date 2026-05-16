import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const twilioAccountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
const twilioAuthToken = Deno.env.get('TWILIO_AUTH_TOKEN');
const twilioPhoneNumber = Deno.env.get('TWILIO_PHONE_NUMBER');

serve(async (req) => {
  try {
    const { to, message, from_name } = await req.json();

    if (!to || !message) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: to, message' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // If Twilio is configured, send SMS
    if (twilioAccountSid && twilioAuthToken && twilioPhoneNumber) {
      const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${twilioAccountSid}/Messages.json`;
      const auth = btoa(`${twilioAccountSid}:${twilioAuthToken}`);

      const formData = new URLSearchParams({
        To: to,
        From: twilioPhoneNumber,
        Body: `💎 Crystal Messenger\n${from_name ? `${from_name}: ` : ''}${message}\n\nReply in the app or tap: https://crystal-messenger.app/chat`,
      });

      const response = await fetch(twilioUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData.toString(),
      });

      const result = await response.json();

      if (!response.ok) {
        console.error('Twilio error:', result);
        return new Response(
          JSON.stringify({ error: 'SMS sending failed', details: result }),
          { status: 500, headers: { 'Content-Type': 'application/json' } },
        );
      }

      console.log('SMS sent successfully:', result.sid);

      return new Response(
        JSON.stringify({
          success: true,
          message_sid: result.sid,
          to: to,
          status: result.status,
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    } else {
      // Twilio not configured - log and return success (simulated)
      console.log(`[SMS Bridge - Simulated] To: ${to}, Message: ${message}`);
      return new Response(
        JSON.stringify({
          success: true,
          simulated: true,
          to: to,
          message: 'Twilio not configured. SMS would have been sent.',
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    }
  } catch (e) {
    console.error('SMS bridge error:', e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});