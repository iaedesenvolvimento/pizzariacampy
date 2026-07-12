import { Hono } from "hono";

const monetizationAdmin = new Hono();

const HTML = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Monetização - Pizzaria Campy</title>
  <link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700&display=swap" rel="stylesheet" />
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Sora',sans-serif;background:#0a0a0a;color:#eef0f2;min-height:100vh;padding:20px}
    .container{max-width:1000px;margin:0 auto}
    h1{font-size:28px;margin-bottom:8px;background:linear-gradient(135deg,#e94560,#f5a623);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .subtitle{color:#8892a4;margin-bottom:32px}
    .tabs{display:flex;gap:8px;margin-bottom:24px;flex-wrap:wrap}
    .tab{padding:12px 20px;border-radius:12px;background:#1a1a2e;border:1px solid rgba(255,255,255,0.06);color:#8892a4;cursor:pointer;font-size:14px;font-weight:500;transition:all 0.2s}
    .tab.active{background:#e94560;color:white;border-color:#e94560}
    .tab:hover{border-color:#e94560}
    .section{display:none;background:#1a1a2e;border-radius:16px;padding:24px;border:1px solid rgba(255,255,255,0.06);margin-bottom:24px}
    .section.active{display:block}
    .section h2{font-size:20px;margin-bottom:16px;display:flex;align-items:center;gap:10px}
    .card{background:#16213e;border-radius:12px;padding:20px;margin-bottom:16px;border:1px solid rgba(255,255,255,0.06)}
    .card-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}
    .card-title{font-size:16px;font-weight:600}
    .badge{padding:4px 12px;border-radius:20px;font-size:11px;font-weight:600}
    .badge-active{background:rgba(39,174,96,0.2);color:#27ae60}
    .badge-inactive{background:rgba(255,255,255,0.1);color:#8892a4}
    .form-group{margin-bottom:16px}
    .form-label{font-size:12px;color:#8892a4;margin-bottom:6px;display:block}
    .form-input{width:100%;padding:12px;border-radius:10px;background:#0a0a0a;border:1px solid rgba(255,255,255,0.06);color:#eef0f2;font-family:'Sora',sans-serif;font-size:14px}
    .form-input:focus{outline:none;border-color:#e94560}
    .form-row{display:grid;grid-template-columns:1fr 1fr;gap:12px}
    .btn{padding:12px 24px;border-radius:10px;border:none;font-family:'Sora',sans-serif;font-size:14px;font-weight:600;cursor:pointer;transition:all 0.2s}
    .btn-primary{background:#e94560;color:white;width:100%}
    .btn-success{background:#27ae60;color:white}
    .btn-danger{background:#e94560;color:white}
    .btn-outline{background:transparent;border:1px solid rgba(255,255,255,0.1);color:#eef0f2}
    .btn:hover{filter:brightness(1.1)}
    .btn-sm{padding:8px 16px;font-size:12px;width:auto}
    .grid-3{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}
    .plan-card{background:#16213e;border-radius:16px;padding:24px;border:2px solid rgba(255,255,255,0.06);text-align:center;transition:all 0.2s}
    .plan-card.popular{border-color:#e94560}
    .plan-icon{font-size:48px;margin-bottom:12px}
    .plan-name{font-size:20px;font-weight:700;margin-bottom:8px}
    .plan-price{font-size:32px;font-weight:800;color:#f5a623;margin-bottom:16px}
    .plan-price small{font-size:14px;color:#8892a4;font-weight:400}
    .plan-features{text-align:left;margin-bottom:20px}
    .plan-features li{padding:8px 0;color:#8892a4;font-size:13px;list-style:none;display:flex;align-items:center;gap:8px}
    .plan-features li::before{content:"✓";color:#27ae60;font-weight:700}
    .stat-box{background:#16213e;border-radius:12px;padding:20px;text-align:center}
    .stat-value{font-size:28px;font-weight:800;color:#f5a623}
    .stat-label{font-size:12px;color:#8892a4;margin-top:4px}
    .list-item{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.06)}
    .list-item:last-child{border-bottom:none}
    .list-info{flex:1}
    .list-title{font-weight:600;font-size:14px}
    .list-sub{color:#8892a4;font-size:12px}
    .actions{display:flex;gap:8px}
    .empty{text-align:center;padding:40px;color:#8892a4}
    .empty-icon{font-size:48px;margin-bottom:12px;opacity:0.5}
    @media(max-width:600px){.form-row{grid-template-columns:1fr}.grid-3{grid-template-columns:1fr}}
  </style>
</head>
<body>
  <div class="container">
    <h1>💰 Monetização</h1>
    <p class="subtitle">Gerencie cupons, assinaturas e programa de fidelidade</p>

    <div class="tabs">
      <div class="tab active" onclick="showTab('coupons')">🎟️ Cupons</div>
      <div class="tab" onclick="showTab('subscriptions')">⭐ Assinaturas</div>
      <div class="tab" onclick="showTab('loyalty')">🏆 Fidelidade</div>
      <div class="tab" onclick="showTab('stats')">📊 Estatísticas</div>
    </div>

    <!-- CUPONS -->
    <div class="section active" id="coupons">
      <h2>🎟️ Cupons de Desconto</h2>
      
      <div class="card">
        <h3 style="margin-bottom:16px">Criar Novo Cupom</h3>
        <div class="form-group">
          <label class="form-label">Código do Cupom</label>
          <input type="text" class="form-input" id="coupon-code" placeholder="Ex: CAMPY10" style="text-transform:uppercase">
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Tipo</label>
            <select class="form-input" id="coupon-type">
              <option value="percentage">Percentual (%)</option>
              <option value="fixed">Valor Fixo (R$)</option>
              <option value="free_delivery">Frete Grátis</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Valor</label>
            <input type="number" class="form-input" id="coupon-value" placeholder="10">
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Pedido Mínimo (R$)</label>
            <input type="number" class="form-input" id="coupon-min" placeholder="0">
          </div>
          <div class="form-group">
            <label class="form-label">Máximo de Usos</label>
            <input type="number" class="form-input" id="coupon-max" placeholder="100">
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Válido De</label>
            <input type="date" class="form-input" id="coupon-from">
          </div>
          <div class="form-group">
            <label class="form-label">Válido Até</label>
            <input type="date" class="form-input" id="coupon-until">
          </div>
        </div>
        <button class="btn btn-primary" onclick="createCoupon()"> Criar Cupom</button>
      </div>

      <div id="coupons-list">
        <div class="empty">
          <div class="empty-icon">🎟️</div>
          <p>Carregando cupons...</p>
        </div>
      </div>
    </div>

    <!-- ASSINATURAS -->
    <div class="section" id="subscriptions">
      <h2>⭐ Planos de Assinatura</h2>
      
      <div class="grid-3">
        <div class="plan-card">
          <div class="plan-icon">🆓</div>
          <div class="plan-name">Gratuito</div>
          <div class="plan-price">R$ 0<small>/mês</small></div>
          <ul class="plan-features">
            <li>Taxa de entrega normal</li>
            <li>Acesso ao cardápio</li>
            <li>1 ponto por R$ 1</li>
          </ul>
          <button class="btn btn-outline" disabled>Plano Atual</button>
        </div>
        
        <div class="plan-card popular">
          <div class="plan-icon">⭐</div>
          <div class="plan-name">Campy Club</div>
          <div class="plan-price">R$ 19,90<small>/mês</small></div>
          <ul class="plan-features">
            <li>Entrega grátis</li>
            <li>10% desconto sempre</li>
            <li>2x pontos</li>
            <li>Ofertas exclusivas</li>
          </ul>
          <button class="btn btn-primary" onclick="alert('Gerencie via API')">Gerenciar</button>
        </div>
        
        <div class="plan-card">
          <div class="plan-icon">👑</div>
          <div class="plan-name">Campy Club+</div>
          <div class="plan-price">R$ 29,90<small>/mês</small></div>
          <ul class="plan-features">
            <li>Tudo do Club</li>
            <li>15% desconto</li>
            <li>Pizza grátis/mês</li>
            <li>Prioridade na fila</li>
            <li>3x pontos</li>
          </ul>
          <button class="btn btn-primary" onclick="alert('Gerencie via API')">Gerenciar</button>
        </div>
      </div>

      <div class="card" style="margin-top:24px">
        <h3 style="margin-bottom:16px">Assinantes Ativos</h3>
        <div id="subscribers-list">
          <div class="empty">
            <div class="empty-icon">👥</div>
            <p>Nenhum assinante ainda</p>
          </div>
        </div>
      </div>
    </div>

    <!-- FIDELIDADE -->
    <div class="section" id="loyalty">
      <h2>🏆 Programa de Fidelidade</h2>
      
      <div class="grid-3" style="margin-bottom:24px">
        <div class="stat-box">
          <div class="stat-value" id="total-points">0</div>
          <div class="stat-label">Pontos Distribuídos</div>
        </div>
        <div class="stat-box">
          <div class="stat-value" id="total-members">0</div>
          <div class="stat-label">Membros Ativos</div>
        </div>
        <div class="stat-box">
          <div class="stat-value" id="total-redeemed">0</div>
          <div class="stat-label">Pontos Resgatados</div>
        </div>
      </div>

      <div class="card">
        <h3 style="margin-bottom:16px">Configurar Regras</h3>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Pontos por R$ 1 gasto</label>
            <input type="number" class="form-input" id="points-per-real" value="1">
          </div>
          <div class="form-group">
            <label class="form-label">Pontos para Resgate</label>
            <input type="number" class="form-input" id="points-for-redeem" value="100">
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Desconto por Resgate (R$)</label>
            <input type="number" class="form-input" id="redeem-value" value="10">
          </div>
          <div class="form-group">
            <label class="form-label">Nível Prata (pontos)</label>
            <input type="number" class="form-input" id="silver-level" value="500">
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Nível Ouro (pontos)</label>
          <input type="number" class="form-input" id="gold-level" value="1000">
        </div>
        <button class="btn btn-primary" onclick="saveLoyaltySettings()">Salvar Configurações</button>
      </div>

      <div class="card">
        <h3 style="margin-bottom:16px">Níveis</h3>
        <div class="list-item">
          <div class="list-info">
            <div class="list-title">🥉 Bronze</div>
            <div class="list-sub">0 - 499 pontos</div>
          </div>
          <span class="badge badge-active">Base</span>
        </div>
        <div class="list-item">
          <div class="list-info">
            <div class="list-title">🥈 Prata</div>
            <div class="list-sub">500 - 999 pontos • +5% desconto</div>
          </div>
          <span class="badge badge-active">500 pts</span>
        </div>
        <div class="list-item">
          <div class="list-info">
            <div class="list-title">🥇 Ouro</div>
            <div class="list-sub">1000+ pontos • +10% desconto + pizza grátis</div>
          </div>
          <span class="badge badge-active">1000 pts</span>
        </div>
      </div>
    </div>

    <!-- ESTATÍSTICAS -->
    <div class="section" id="stats">
      <h2>📊 Estatísticas</h2>
      
      <div class="grid-3" style="margin-bottom:24px">
        <div class="stat-box">
          <div class="stat-value" id="stat-coupons">0</div>
          <div class="stat-label">Cupons Criados</div>
        </div>
        <div class="stat-box">
          <div class="stat-value" id="stat-used">0</div>
          <div class="stat-label">Cupons Utilizados</div>
        </div>
        <div class="stat-box">
          <div class="stat-value" id="stat-saved">R$ 0</div>
          <div class="stat-label">Total Economizado</div>
        </div>
      </div>

      <div class="card">
        <h3 style="margin-bottom:16px">Receita por Fonte</h3>
        <div class="list-item">
          <div class="list-info">
            <div class="list-title">🚚 Taxas de Entrega</div>
            <div class="list-sub">Cobrança por distância</div>
          </div>
          <span class="badge badge-active" id="rev-delivery">R$ 0</span>
        </div>
        <div class="list-item">
          <div class="list-info">
            <div class="list-title">⭐ Assinaturas</div>
            <div class="list-sub">Campy Club e Club+</div>
          </div>
          <span class="badge badge-active" id="rev-subs">R$ 0</span>
        </div>
        <div class="list-item">
          <div class="list-info">
            <div class="list-title">🎟️ Descontos Concedidos</div>
            <div class="list-sub">Cupons e fidelidade</div>
          </div>
          <span class="badge badge-inactive" id="rev-discounts">-R$ 0</span>
        </div>
      </div>
    </div>
  </div>

  <script>
    const API = window.location.origin;
    let coupons = [];

    function showTab(tab) {
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
      event.target.classList.add('active');
      document.getElementById(tab).classList.add('active');
      
      if (tab === 'coupons') loadCoupons();
      if (tab === 'stats') loadStats();
    }

    async function loadCoupons() {
      try {
        const res = await fetch(API + '/api/public/monetization/coupons');
        const data = await res.json();
        if (data.ok) {
          coupons = data.coupons;
          renderCoupons();
        }
      } catch (e) {
        console.error('Erro ao carregar cupons:', e);
      }
    }

    function renderCoupons() {
      const el = document.getElementById('coupons-list');
      if (!coupons.length) {
        el.innerHTML = '<div class="empty"><div class="empty-icon">🎟️</div><p>Nenhum cupom criado</p></div>';
        return;
      }
      el.innerHTML = coupons.map(c => {
        const typeLabel = c.type === 'percentage' ? c.value + '%' : c.type === 'fixed' ? 'R$ ' + c.value : 'Frete Grátis';
        return '<div class="card"><div class="card-header"><div class="card-title">🎟️ ' + c.code + '</div><span class="badge ' + (c.active ? 'badge-active' : 'badge-inactive') + '">' + (c.active ? 'Ativo' : 'Inativo') + '</span></div><div class="list-item"><div class="list-info"><div class="list-sub">Tipo: ' + typeLabel + ' | Mínimo: R$ ' + (c.minOrder || 0) + ' | Usos: ' + c.usedCount + '/' + (c.maxUses || '∞') + '</div></div><div class="actions"><button class="btn btn-sm btn-outline" onclick="toggleCoupon(\\''+c.id+'\\')">Toggle</button><button class="btn btn-sm btn-danger" onclick="deleteCoupon(\\''+c.id+'\\')">Excluir</button></div></div></div>';
      }).join('');
    }

    async function createCoupon() {
      const code = document.getElementById('coupon-code').value.toUpperCase();
      const type = document.getElementById('coupon-type').value;
      const value = parseFloat(document.getElementById('coupon-value').value);
      const minOrder = parseFloat(document.getElementById('coupon-min').value) || 0;
      const maxUses = parseInt(document.getElementById('coupon-max').value) || 100;
      const validFrom = document.getElementById('coupon-from').value;
      const validUntil = document.getElementById('coupon-until').value;

      if (!code || !value || !validFrom || !validUntil) {
        alert('Preencha todos os campos obrigatórios');
        return;
      }

      try {
        const res = await fetch(API + '/api/public/admin/coupons', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-Admin-Token': localStorage.getItem('admin_token') || '' },
          body: JSON.stringify({ code, type, value, minOrder, maxUses, validFrom, validUntil })
        });
        const data = await res.json();
        if (data.ok) {
          alert('Cupom criado com sucesso!');
          loadCoupons();
          clearCouponForm();
        } else {
          alert('Erro: ' + (data.error || 'Desconhecido'));
        }
      } catch (e) {
        alert('Erro ao criar cupom');
      }
    }

    function clearCouponForm() {
      document.getElementById('coupon-code').value = '';
      document.getElementById('coupon-value').value = '';
      document.getElementById('coupon-min').value = '';
      document.getElementById('coupon-max').value = '';
    }

    async function toggleCoupon(id) {
      try {
        await fetch(API + '/api/public/admin/coupons/' + id + '/toggle', {
          method: 'PATCH',
          headers: { 'X-Admin-Token': localStorage.getItem('admin_token') || '' }
        });
        loadCoupons();
      } catch (e) {
        alert('Erro ao atualizar cupom');
      }
    }

    async function deleteCoupon(id) {
      if (!confirm('Excluir este cupom?')) return;
      try {
        await fetch(API + '/api/public/admin/coupons/' + id, {
          method: 'DELETE',
          headers: { 'X-Admin-Token': localStorage.getItem('admin_token') || '' }
        });
        loadCoupons();
      } catch (e) {
        alert('Erro ao excluir cupom');
      }
    }

    async function loadStats() {
      try {
        const res = await fetch(API + '/api/public/monetization/stats');
        const data = await res.json();
        if (data.ok) {
          document.getElementById('stat-coupons').textContent = data.totalCoupons || 0;
          document.getElementById('stat-used').textContent = data.totalUsed || 0;
          document.getElementById('stat-saved').textContent = 'R$ ' + (data.totalSaved || 0).toFixed(2);
        }
      } catch (e) {
        console.error('Erro ao carregar stats:', e);
      }
    }

    function saveLoyaltySettings() {
      alert('Configurações salvas! (Implementar via API)');
    }

    // Carregar dados iniciais
    loadCoupons();
  </script>
</body>
</html>`;

monetizationAdmin.get("/", (c) => {
  c.header("Content-Type", "text/html; charset=utf-8");
  return c.body(HTML);
});

export default monetizationAdmin;
