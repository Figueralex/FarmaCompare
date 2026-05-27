import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Manejo de preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Inicializar cliente Supabase de forma segura con la clave de servicio del sistema
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 2. Definir límites del reporte (últimas 24 horas)
    const now = new Date();
    const past24h = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();

    // 3. Consultar Top 30 Búsquedas más frecuentes
    const { data: searchLogs, error: searchError } = await supabaseClient
      .from("search_logs")
      .select("query")
      .gte("created_at", past24h);

    if (searchError) throw searchError;

    // Agrupar y ordenar búsquedas
    const searchCounts: Record<string, number> = {};
    searchLogs?.forEach((log: { query: string }) => {
      const q = log.query.trim().toLowerCase();
      searchCounts[q] = (searchCounts[q] || 0) + 1;
    });

    const topSearches = Object.entries(searchCounts)
      .map(([query, count]) => ({ query, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 30);

    // 4. Consultar clics por farmacia en las últimas 24h
    const { data: clickLogs, error: clickError } = await supabaseClient
      .from("click_logs")
      .select("pharmacy_name")
      .gte("created_at", past24h);

    if (clickError) throw clickError;

    // Inicializar el conteo de las 4 farmacias conocidas
    const pharmacyCounts: Record<string, number> = {
      "Farmatodo": 0,
      "Farmapaz": 0,
      "Farmadon": 0,
      "Farmatina": 0
    };

    let totalRedirects = 0;
    clickLogs?.forEach((log: { pharmacy_name: string }) => {
      const name = log.pharmacy_name;
      // Normalizar nombre de farmacia (primera letra mayúscula)
      const normalizedName = name.charAt(0).toUpperCase() + name.slice(1).toLowerCase();
      pharmacyCounts[normalizedName] = (pharmacyCounts[normalizedName] || 0) + 1;
      totalRedirects++;
    });

    // 5. Construir plantilla HTML del correo
    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Reporte Diario FarmaCompare</title>
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f4f6f9; color: #333; margin: 0; padding: 20px; }
          .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); overflow: hidden; border: 1px solid #e1e8ed; }
          .header { background: linear-gradient(135deg, #1e88e5 0%, #1565c0 100%); color: #ffffff; padding: 30px 20px; text-align: center; }
          .header h1 { margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.5px; }
          .header p { margin: 5px 0 0 0; font-size: 14px; opacity: 0.9; }
          .section { padding: 25px 20px; border-bottom: 1px solid #eff2f5; }
          .section-title { font-size: 18px; font-weight: 700; color: #1e88e5; margin-top: 0; margin-bottom: 15px; border-left: 4px solid #1e88e5; padding-left: 10px; }
          .pharmacy-grid { display: table; width: 100%; border-collapse: separate; border-spacing: 10px; margin: -10px auto; }
          .pharmacy-card { display: table-cell; width: 50%; background: #f8f9fa; border: 1px solid #e9ecef; border-radius: 8px; padding: 15px; text-align: center; }
          .pharmacy-name { font-size: 14px; font-weight: 600; color: #495057; margin-bottom: 5px; }
          .pharmacy-count { font-size: 24px; font-weight: 800; color: #2e7d32; }
          .top-list { list-style: none; padding: 0; margin: 0; }
          .top-item { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px dashed #e9ecef; font-size: 14px; }
          .top-item:last-child { border-bottom: none; }
          .top-rank { font-weight: 700; color: #1e88e5; width: 30px; }
          .top-query { flex-grow: 1; text-align: left; }
          .top-count { font-weight: 600; color: #6c757d; }
          .footer { background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #6c757d; border-top: 1px solid #eff2f5; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>FarmaCompare Analytics</h1>
            <p>Reporte Diario Automatizado de Rendimiento</p>
          </div>
          
          <div class="section">
            <h2 class="section-title">🏥 Clics y Redireccionamientos por Farmacia</h2>
            <div class="pharmacy-grid">
              <div class="pharmacy-card">
                <div class="pharmacy-name">Farmatodo</div>
                <div class="pharmacy-count">${pharmacyCounts["Farmatodo"]}</div>
              </div>
              <div class="pharmacy-card">
                <div class="pharmacy-name">Farmapaz</div>
                <div class="pharmacy-count">${pharmacyCounts["Farmapaz"]}</div>
              </div>
            </div>
            <div class="pharmacy-grid" style="margin-top: 10px;">
              <div class="pharmacy-card">
                <div class="pharmacy-name">Farmadon</div>
                <div class="pharmacy-count">${pharmacyCounts["Farmadon"]}</div>
              </div>
              <div class="pharmacy-card">
                <div class="pharmacy-name">Farmatina</div>
                <div class="pharmacy-count">${pharmacyCounts["Farmatina"]}</div>
              </div>
            </div>
            <p style="text-align: center; margin-top: 15px; font-weight: bold; color: #495057;">
              Total de redirecciones en las últimas 24h: ${totalRedirects}
            </p>
          </div>

          <div class="section">
            <h2 class="section-title">🔍 Top Búsquedas Frecuentes (Últimas 24h)</h2>
            <ul class="top-list">
              ${topSearches.length === 0 
                ? '<li style="text-align: center; color: #6c757d; padding: 20px;">No se registraron búsquedas en este período.</li>'
                : topSearches.map((item, idx) => `
                  <li class="top-item">
                    <span class="top-rank">#${idx + 1}</span>
                    <span class="top-query">${item.query}</span>
                    <span class="top-count">${item.count} búsquedas</span>
                  </li>
                `).join('')
              }
            </ul>
          </div>
          
          <div class="footer">
            Este reporte fue generado de forma automática por Supabase Edge Functions.<br>
            © ${now.getFullYear()} FarmaCompare - Todos los derechos reservados.
          </div>
        </div>
      </body>
      </html>
    `;

    // 6. Enviar el correo usando Resend API
    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    const TO_EMAIL = Deno.env.get("ADMIN_EMAIL") ?? "tu-email@gmail.com";

    if (!RESEND_API_KEY) {
      throw new Error("La clave RESEND_API_KEY no está configurada.");
    }

    const emailResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "FarmaCompare Analytics <onboarding@resend.dev>", // Cambia a tu dominio verificado cuando configures Resend
        to: [TO_EMAIL],
        subject: `📊 Reporte Diario FarmaCompare: ${now.toLocaleDateString("es-VE")}`,
        html: emailHtml,
      }),
    });

    const emailResult = await emailResponse.json();
    if (!emailResponse.ok) {
      throw new Error(`Error de Resend: ${JSON.stringify(emailResult)}`);
    }

    return new Response(JSON.stringify({ success: true, emailResult }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
