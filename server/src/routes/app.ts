import { Hono } from "hono";

const app = new Hono();

const APP_HTML = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Pizzaria Campy</title>
  <meta name="description" content="Pizzaria Campy - Arte em cada fatia. Peça sua pizza favorita!" />
  <meta name="theme-color" content="#1a1a2e" />
  <meta name="apple-mobile-web-app-capable" content="yes" />
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
  <meta name="apple-mobile-web-app-title" content="Pizzaria Campy" />
  <link rel="manifest" href="/api/public/manifest.json" />
  <link rel="apple-touch-icon" href="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTgwIiBoZWlnaHQ9IjE4MCIgdmlld0JveD0iMCAwIDE4MCAxODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGNpcmNsZSBjeD0iOTAiIGN5PSI5MCIgcj0iOTAiIGZpbGw9IiMxYTFhMmUiLz48Y2lyY2xlIGN4PSI5MCIgY3k9IjkwIiByPSI4MCIgZmlsbD0iI2U5NDU2MCIvPjxwYXRoIGQ9Ik05MCAyMEwxMTAgMTIwSDcwTDkwIDIwWiIgZmlsbD0iI2Y1YTYyMyIvPjxwYXRoIGQ9Ik05MCAyOEwxMTYgMTIwSDE2NEw5MCAyOFoiIGZpbGw9IiNmZmY4ZTciLz48Y2lyY2xlIGN4PSI3OCIgY3k9Ijg1IiByPSIxMCIgZmlsbD0iI2U5NDU2MCIvPjxjaXJjbGUgY3g9IjEwMiIgY3k9IjkzIiByPSI4IiBmaWxsPSIjZTk0NTYwIi8+PGNpcmNsZSBjeD0iOTAiIGN5PSIxMDUiIHI9IjciIGZpbGw9IiNlOTQ1NjAiLz48L3N2Zz4=" />
  <link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700&display=swap" rel="stylesheet" />
  <style>
    :root{--primary:#1a1a2e;--accent:#e94560;--gold:#f5a623;--surface:#16213e;--surface-light:#1f2f50;--text:#eef0f2;--muted:#8892a4;--success:#27ae60;--border:rgba(255,255,255,0.06);--radius:14px;--radius-sm:10px}
    *{box-sizing:border-box;margin:0;padding:0}body{font-family:'Sora',sans-serif;background:var(--primary);color:var(--text);min-height:100vh}
    .header{background:linear-gradient(135deg,var(--surface),var(--primary));border-bottom:1px solid var(--border);padding:16px;position:sticky;top:0;z-index:100}
    .header-inner{max-width:600px;margin:0 auto;display:flex;align-items:center;justify-content:space-between}
    .brand{display:flex;align-items:center;gap:12px}.brand h1{font-size:18px;font-weight:700}.brand span{font-size:11px;color:var(--muted)}
    .btn{padding:10px 20px;border-radius:20px;font-size:13px;font-weight:500;cursor:pointer;border:1px solid var(--border);background:var(--surface-light);color:var(--text);transition:all 0.2s}
    .btn:hover{background:var(--accent);border-color:var(--accent)}
    .main{max-width:600px;margin:0 auto;padding:16px}
    .tabs{display:flex;gap:6px;overflow-x:auto;padding-bottom:12px;scrollbar-width:none}.tabs::-webkit-scrollbar{display:none}
    .tab{padding:8px 16px;border-radius:20px;font-size:13px;font-weight:500;white-space:nowrap;cursor:pointer;background:var(--surface);color:var(--muted);border:1px solid var(--border);transition:all 0.2s}
    .tab.active{background:var(--accent);color:white;border-color:var(--accent)}
    .menu-grid{display:flex;flex-direction:column;gap:12px}
    .menu-item{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:16px;display:flex;gap:14px;cursor:pointer;transition:all 0.2s}
    .menu-item:hover{border-color:var(--accent)}
    .menu-icon{width:60px;height:60px;border-radius:var(--radius-sm);background:var(--surface-light);display:flex;align-items:center;justify-content:center;font-size:28px;flex-shrink:0}
    .menu-info{flex:1}.menu-name{font-size:15px;font-weight:600;margin-bottom:4px}.menu-desc{font-size:12px;color:var(--muted);line-height:1.4;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
    .menu-footer{display:flex;justify-content:space-between;align-items:center;margin-top:8px}.menu-price{font-size:16px;font-weight:700;color:var(--gold)}
    .add-btn{width:36px;height:36px;border-radius:50%;background:var(--accent);color:white;border:none;font-size:18px;cursor:pointer;display:flex;align-items:center;justify-content:center}
    .cart-badge{position:relative}.cart-count{position:absolute;top:-4px;right:-4px;background:var(--accent);color:white;font-size:10px;font-weight:700;width:18px;height:18px;border-radius:50%;display:flex;align-items:center;justify-content:center}
    .empty{text-align:center;padding:60px 20px;color:var(--muted)}.empty-icon{font-size:48px;margin-bottom:12px;opacity:0.5}
    .loading{text-align:center;padding:60px;color:var(--muted)}
    .error{text-align:center;padding:40px;color:var(--accent)}
    .toast{position:fixed;bottom:20px;left:50%;transform:translateX(-50%);background:var(--success);color:white;padding:12px 24px;border-radius:30px;font-size:13px;font-weight:500;z-index:300;box-shadow:0 8px 32px rgba(0,0,0,0.3)}
    .modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.7);z-index:200;display:none;align-items:flex-end;justify-content:center;backdrop-filter:blur(4px)}.modal-overlay.active{display:flex}
    .modal{background:var(--surface);border-radius:20px 20px 0 0;width:100%;max-width:600px;max-height:85vh;overflow-y:auto;animation:slideUp 0.3s}
    @keyframes slideUp{from{transform:translateY(100%)}to{transform:translateY(0)}}
    .modal-header{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center}
    .modal-close{width:32px;height:32px;border-radius:50%;background:var(--surface-light);border:none;color:var(--text);cursor:pointer;font-size:16px}
    .modal-body{padding:20px}
    .size-sel{display:flex;gap:8px;margin-bottom:16px}
    .size-btn{flex:1;padding:12px;border-radius:var(--radius-sm);background:var(--surface-light);border:2px solid var(--border);text-align:center;cursor:pointer;transition:all 0.2s}
    .size-btn.active{border-color:var(--accent);background:rgba(233,69,96,0.1)}
    .size-label{font-size:11px;color:var(--muted)}.size-price{font-size:16px;font-weight:700}
    .qty-row{display:flex;align-items:center;justify-content:center;gap:20px;margin:20px 0}
    .qty-btn{width:44px;height:44px;border-radius:50%;background:var(--surface-light);border:1px solid var(--border);color:var(--text);font-size:20px;cursor:pointer}
    .qty-val{font-size:24px;font-weight:700;min-width:40px;text-align:center}
    .notes{width:100%;padding:12px;border-radius:var(--radius-sm);background:var(--surface-light);border:1px solid var(--border);color:var(--text);font-family:'Sora',sans-serif;font-size:14px;resize:none;min-height:60px}
    .notes::placeholder{color:var(--muted)}
    .add-cart-btn{width:100%;padding:16px;border-radius:var(--radius);background:var(--accent);color:white;border:none;font-family:'Sora',sans-serif;font-size:16px;font-weight:600;cursor:pointer;margin-top:16px}
    .cart-panel{position:fixed;inset:0;background:rgba(0,0,0,0.7);z-index:200;display:none;align-items:flex-end;justify-content:center;backdrop-filter:blur(4px)}.cart-panel.active{display:flex}
    .cart-content{background:var(--surface);border-radius:20px 20px 0 0;width:100%;max-width:600px;max-height:90vh;overflow-y:auto}
    .cart-header{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center}
    .cart-items{padding:16px 20px}.cart-item{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--border)}
    .cart-item:last-child{border-bottom:none}.cart-item-info{flex:1}.cart-item-name{font-size:14px;font-weight:600}.cart-item-detail{font-size:12px;color:var(--muted)}
    .cart-item-qty{display:flex;align-items:center;gap:8px}.cart-qty{width:28px;height:28px;border-radius:50%;background:var(--surface-light);border:1px solid var(--border);color:var(--text);cursor:pointer}
    .cart-item-price{font-weight:600;color:var(--gold)}
    .cart-summary{padding:16px 20px;border-top:1px solid var(--border)}.summary-row{display:flex;justify-content:space-between;margin-bottom:8px;font-size:14px}
    .summary-row.total{font-size:18px;font-weight:700;margin-top:12px;padding-top:12px;border-top:1px solid var(--border)}.summary-total{color:var(--gold)}
    .form-group{margin-bottom:16px}.form-label{font-size:12px;color:var(--muted);margin-bottom:6px;display:block;font-weight:500}
    .form-input{width:100%;padding:14px 16px;border-radius:var(--radius-sm);background:var(--surface-light);border:1px solid var(--border);color:var(--text);font-family:'Sora',sans-serif;font-size:14px}
    .form-input:focus{outline:none;border-color:var(--accent)}.form-input[readonly]{opacity:0.7}
    .pay-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:16px}
    .pay-btn{padding:14px;border-radius:var(--radius-sm);background:var(--surface-light);border:2px solid var(--border);text-align:center;cursor:pointer;transition:all 0.2s;font-size:13px;font-weight:500}
    .pay-btn.active{border-color:var(--accent);background:rgba(233,69,96,0.1)}
    .pay-icon{font-size:20px;margin-bottom:4px}
    .cash-change{margin-top:12px;padding:12px;background:var(--surface-light);border-radius:var(--radius-sm);border:1px solid var(--border);display:none}
    .cash-change.active{display:block}
    .cash-change label{font-size:12px;color:var(--muted);margin-bottom:6px;display:block;font-weight:500}
    .cash-change input{width:100%;padding:12px;border-radius:8px;background:var(--surface);border:1px solid var(--border);color:var(--text);font-family:'Sora',sans-serif;font-size:14px}
    .cash-change input:focus{outline:none;border-color:var(--accent)}
    .checkout-btn{width:100%;padding:16px;border-radius:var(--radius);background:var(--success);color:white;border:none;font-family:'Sora',sans-serif;font-size:16px;font-weight:600;cursor:pointer}
    .auth-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.8);z-index:250;display:none;align-items:center;justify-content:center;backdrop-filter:blur(8px)}.auth-overlay.active{display:flex}
    .auth-card{background:var(--surface);border-radius:20px;width:90%;max-width:400px;padding:32px 24px}
    .auth-title{font-size:22px;font-weight:700;text-align:center;margin-bottom:8px}.auth-sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:24px}
    .auth-tabs{display:flex;gap:4px;margin-bottom:24px;background:var(--surface-light);border-radius:10px;padding:4px}
    .auth-tab{flex:1;padding:10px;text-align:center;border-radius:8px;font-size:14px;font-weight:500;cursor:pointer;color:var(--muted);transition:all 0.2s}.auth-tab.active{background:var(--accent);color:white}
    .auth-link{text-align:center;margin-top:16px;font-size:13px;color:var(--muted)}.auth-link a{color:var(--accent);cursor:pointer}
    .user-btn{width:auto;padding:0 12px;border-radius:20px;gap:6px;display:flex;align-items:center}
    .user-avatar{width:28px;height:28px;border-radius:50%;background:var(--accent);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:white}
    .user-menu{position:absolute;top:50px;right:16px;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-sm);padding:8px;min-width:180px;z-index:150;display:none;box-shadow:0 8px 32px rgba(0,0,0,0.3)}.user-menu.active{display:block}
    .user-menu-item{padding:10px 12px;border-radius:8px;font-size:13px;cursor:pointer;display:flex;align-items:center;gap:8px;color:var(--text);transition:background 0.2s}.user-menu-item:hover{background:var(--surface-light)}
    .order-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:16px;margin-bottom:12px;cursor:pointer}
    .order-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
    .order-id{font-weight:700;font-size:14px}.order-status{font-size:11px;padding:4px 10px;border-radius:12px;font-weight:600}
    .status-pending{background:rgba(245,166,35,0.2);color:var(--gold)}.status-confirmed{background:rgba(100,149,237,0.2);color:cornflowerblue}
    .status-preparing{background:rgba(233,69,96,0.2);color:var(--accent)}.status-out_for_delivery{background:rgba(100,149,237,0.2);color:cornflowerblue}
    .status-delivered{background:rgba(39,174,96,0.2);color:var(--success)}.status-cancelled{background:rgba(255,255,255,0.1);color:var(--muted)}
    .order-items{font-size:13px;color:var(--muted);margin-bottom:8px}.order-total{font-weight:700;color:var(--gold)}
    .tracking-container{padding:20px}
    .tracking-id{text-align:center;font-size:14px;color:var(--muted);margin-bottom:24px}.tracking-id span{font-weight:700;color:var(--gold)}
    .tracking-steps{position:relative;padding-left:30px}.tracking-steps::before{content:'';position:absolute;left:11px;top:8px;bottom:8px;width:2px;background:var(--border)}
    .tracking-step{position:relative;padding:12px 0;padding-left:20px}
    .step-dot{position:absolute;left:-30px;top:14px;width:24px;height:24px;border-radius:50%;background:var(--surface-light);border:2px solid var(--border);display:flex;align-items:center;justify-content:center;font-size:12px;z-index:1}
    .tracking-step.completed .step-dot{background:var(--success);border-color:var(--success);color:white}
    .tracking-step.active .step-dot{background:var(--accent);border-color:var(--accent);color:white;animation:pulse 2s infinite}
    @keyframes pulse{0%,100%{box-shadow:0 0 0 0 rgba(233,69,96,0.4)}50%{box-shadow:0 0 0 8px rgba(233,69,96,0)}}
    .step-label{font-size:14px;font-weight:600}.step-time{font-size:11px;color:var(--muted);margin-top:2px}
    .success{text-align:center;padding:40px 20px}
    .success-icon{font-size:64px;margin-bottom:16px}
    .success-title{font-size:22px;font-weight:700;margin-bottom:8px}
    .success-sub{font-size:14px;color:var(--muted);margin-bottom:24px}
    .success-id{background:var(--surface-light);border-radius:var(--radius-sm);padding:12px 20px;display:inline-block;font-size:16px;font-weight:600;color:var(--gold);margin-bottom:20px}
    .hidden{display:none!important}
    @keyframes popIn{from{transform:scale(0.8);opacity:0}to{transform:scale(1);opacity:1}}
    .popup-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.8);z-index:9999;display:flex;align-items:center;justify-content:center;backdrop-filter:blur(8px)}
    .popup{background:var(--surface);border-radius:28px;padding:48px 36px 40px;text-align:center;max-width:380px;width:88%;animation:popIn 0.4s cubic-bezier(0.175,0.885,0.32,1.275);box-shadow:0 24px 80px rgba(0,0,0,0.6);border:2px solid var(--border)}
    .popup-icon{font-size:80px;margin-bottom:20px;animation:bounce 0.6s ease}
    @keyframes bounce{0%,100%{transform:scale(1)}50%{transform:scale(1.1)}}
    .popup-title{font-size:24px;font-weight:700;margin-bottom:12px;line-height:1.3}
    .popup-sub{color:var(--muted);font-size:15px;margin-bottom:24px;line-height:1.5}
    .popup-btn{padding:16px 48px;border-radius:16px;border:none;font-family:Sora;font-size:18px;font-weight:700;cursor:pointer;color:white;transition:transform 0.2s;min-width:140px}
    .popup-btn:hover{transform:scale(1.05)}
    .popup-btn:active{transform:scale(0.95)}
    .btns{display:flex;gap:10px;margin-top:12px}
    .btn-success{padding:10px 18px;border-radius:12px;font-size:13px;font-weight:600;cursor:pointer;border:none;background:var(--success);color:white;transition:all 0.2s;flex:1}
    .btn-success:hover{opacity:0.9;transform:translateY(-1px)}
    .btn-outline{padding:10px 18px;border-radius:12px;font-size:13px;font-weight:600;cursor:pointer;border:1px solid var(--border);background:transparent;color:var(--text);transition:all 0.2s;flex:1}
    .btn-outline:hover{background:var(--surface-light);border-color:var(--accent)}
    
    .splash{position:fixed;inset:0;z-index:9999;display:flex;flex-direction:column;align-items:center;justify-content:center;background:#0a0a0a;transition:opacity 0.6s ease}
    .splash::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse at center,transparent 40%,rgba(200,30,30,0.12) 100%);pointer-events:none}
    .splash::after{content:'';position:absolute;inset:0;background:radial-gradient(ellipse at bottom,rgba(200,30,30,0.08) 0%,transparent 60%);pointer-events:none}
    .splash-content{position:relative;z-index:1;text-align:center;animation:splashFadeIn 0.8s ease}
    .pizza-icon{width:140px;height:140px;margin:0 auto 36px;position:relative}
    .pizza-slice{position:absolute;width:0;height:0;border-left:55px solid transparent;border-right:55px solid transparent;border-bottom:100px solid #e94560;transform:rotate(-30deg);filter:drop-shadow(0 0 30px rgba(233,69,96,0.6));top:0;left:50%;margin-left:-55px}
    .pizza-crust{position:absolute;bottom:0;left:50%;transform:translateX(-50%) rotate(-30deg);width:80px;height:14px;background:linear-gradient(90deg,#f5a623,#e94560);border-radius:0 0 40px 40px;box-shadow:0 0 20px rgba(245,166,35,0.6)}
    .pizza-cheese{position:absolute;top:30px;left:50%;transform:translateX(-50%) rotate(-30deg);width:0;height:0;border-left:28px solid transparent;border-right:28px solid transparent;border-bottom:50px solid #fff;border-bottom-left-radius:5px;border-bottom-right-radius:5px;opacity:0.85}
    .splash-name{font-size:36px;font-weight:800;letter-spacing:-1px;margin-bottom:10px;background:linear-gradient(135deg,#fff 0%,#e0e0e0 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;font-family:'Poppins',sans-serif}
    .splash-slogan{font-size:14px;color:rgba(255,255,255,0.45);font-weight:400;letter-spacing:0.3px;font-family:'Poppins',sans-serif}
    .splash-progress{position:absolute;bottom:60px;left:50%;transform:translateX(-50%);width:180px;height:3px;background:rgba(255,255,255,0.08);border-radius:2px;overflow:hidden}
    .splash-progress-bar{height:100%;background:linear-gradient(90deg,#e94560,#f5a623);width:0%;border-radius:2px;animation:splashLoad 2.2s ease-in-out forwards}
    @keyframes splashFadeIn{from{opacity:0;transform:translateY(25px)}to{opacity:1;transform:translateY(0)}}
    @keyframes splashLoad{0%{width:0%}100%{width:100%}}
    .splash.hidden{opacity:0;pointer-events:none}
  </style>
</head>
<body>
  <!-- Splash Screen -->
  <div class="splash" id="splash">
    <div class="splash-content">
      <div class="pizza-icon">
        <div class="pizza-slice"></div>
        <div class="pizza-cheese"></div>
        <div class="pizza-crust"></div>
      </div>
      <div class="splash-name">Pizzaria Campy</div>
      <div class="splash-slogan">Pizza quentinha, entregue com rapidez.</div>
    </div>
    <div class="splash-progress">
      <div class="splash-progress-bar"></div>
    </div>
  </div>

  <div class="header">
    <div class="header-inner">
      <div class="brand"><h1>🍕 Pizzaria Campy</h1><span>Arte em cada fatia</span></div>
      <div style="display:flex;gap:8px;align-items:center">
        <button class="btn" id="btn-orders" title="Pedidos">📦</button>
        <button class="btn cart-badge" id="btn-cart">🛒 <span class="cart-count hidden" id="cart-count">0</span></button>
        <button class="btn user-btn" id="btn-user">👤</button>
      </div>
    </div>
    <div class="user-menu" id="user-menu"></div>
  </div>

  <div class="main">
    <div id="view-menu">
      <div class="tabs" id="tabs"></div>
      <div class="menu-grid" id="menu-grid"><div class="loading">Carregando cardápio...</div></div>
    </div>
    <div id="view-orders" class="hidden"></div>
    <div id="view-tracking" class="hidden"></div>
    <div id="view-success" class="hidden"></div>
  </div>

  <div class="modal-overlay" id="modal-item"><div class="modal"><div class="modal-header"><span style="font-weight:600">Personalizar</span><button class="modal-close" onclick="closeModal()">✕</button></div><div class="modal-body" id="modal-body"></div></div></div>
  <div class="cart-panel" id="cart-panel"><div class="cart-content"><div class="cart-header"><span style="font-weight:700;font-size:18px">🛒 Seu Pedido</span><button class="modal-close" onclick="closeCart()">✕</button></div><div id="cart-body"></div></div></div>
  <div class="auth-overlay" id="auth-overlay"><div class="auth-card"><div class="auth-title" id="auth-title">Entrar</div><div class="auth-sub" id="auth-sub">Acesse sua conta para ver seus pedidos</div><div class="auth-tabs"><div class="auth-tab active" id="tab-login" onclick="showAuthTab('login')">Entrar</div><div class="auth-tab" id="tab-register" onclick="showAuthTab('register')">Cadastrar</div></div><div id="auth-form"></div></div></div>

  <script>
    var API_BASE=window.location.origin,menuItems=[],cart=[],currentCategory="all",selectedItem=null,selectedSize=null,selectedQty=1,selectedPayment="pix",currentUser=null,authToken=localStorage.getItem("campy_token"),trackingInterval=null,lastTrackingStatus=null,cashChangeFor=null,selectedExtras=[];
    var CAT={pizza_classica:{l:"Clássicas",e:"🍕"},pizza_premium:{l:"Premium",e:"✨"},pizza_doce:{l:"Doces",e:"🍫"},bebida:{l:"Bebidas",e:"🥤"},sobremesa:{l:"Sobremesas",e:"🍰"}};
    var PAY=[{k:"pix",l:"PIX",i:"📱"},{k:"credit_card",l:"Crédito",i:"💳"},{k:"debit_card",l:"Débito",i:"💳"},{k:"cash",l:"Dinheiro",i:"💵"}];;
    var STS=[{k:"pending",l:"Aguardando",i:"⏳"},{k:"confirmed",l:"Confirmado",i:"✅"},{k:"preparing",l:"Preparando",i:"👨‍🍳"},{k:"out_for_delivery",l:"Em entrega",i:"🛵"},{k:"delivered",l:"Entregue",i:"🎉"}];

    function apiGet(p){return fetch(API_BASE+"/api/public"+p).then(function(r){return r.json()})}
    function apiPost(p,b){return fetch(API_BASE+"/api/public"+p,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(b)}).then(function(r){return r.json()})}
    function apiGetAuth(p){return fetch(API_BASE+"/api/public"+p,{headers:{"Authorization":"Bearer "+authToken}}).then(function(r){return r.json()})}
    function maskPhone(v){v=v.replace(/\\D/g,"").slice(0,11);return v.length<=10?v.replace(/(\\d{2})(\\d{4})(\\d{0,4})/,"($1) $2-$3").replace(/-$/,""):v.replace(/(\\d{2})(\\d{5})(\\d{0,4})/,"($1) $2-$3").replace(/-$/,"")}
    function maskCEP(v){v=v.replace(/\\D/g,"").slice(0,8);return v.replace(/(\\d{5})(\\d{0,3})/,"$1-$2").replace(/-$/,"")}

    function showToast(m){var t=document.createElement("div");t.className="toast";t.textContent=m;document.body.appendChild(t);setTimeout(function(){t.remove()},2500)}
    function showPopup(icon,title,sub,color){var d=document.createElement("div");d.className="popup-overlay";d.innerHTML='<div class="popup"><div class="popup-icon">'+icon+'</div><div class="popup-title" style="color:'+(color||'var(--text)')+'">'+title+'</div><div class="popup-sub">'+sub+'</div><button class="popup-btn" style="background:'+(color||'var(--accent)')+'" onclick="this.closest(\\'.popup-overlay\\').remove()">OK</button></div>';document.body.appendChild(d);d.onclick=function(e){if(e.target===d)d.remove()};setTimeout(function(){if(d.parentElement)d.remove()},15000)}
    function playSound(freqs,dur){try{var ctx=new(window.AudioContext||window.webkitAudioContext)();freqs.forEach(function(f,i){var o=ctx.createOscillator(),g=ctx.createGain();o.connect(g);g.connect(ctx.destination);o.frequency.value=f;o.type="sine";g.gain.value=0.2;g.gain.exponentialRampToValueAtTime(0.01,ctx.currentTime+(dur||0.2)+i*0.1);o.start(ctx.currentTime+i*0.1);o.stop(ctx.currentTime+(dur||0.2)+i*0.1)})}catch(e){}}

    function showView(n){["menu","orders","tracking","success"].forEach(function(v){document.getElementById("view-"+v).classList.toggle("hidden",v!==n)})}
    function renderTabs(){var cats=[];menuItems.forEach(function(i){if(cats.indexOf(i.category)===-1)cats.push(i.category)});document.getElementById("tabs").innerHTML='<div class="tab '+(currentCategory==="all"?"active":"")+'" onclick="setCat(\\'all\\')">Todos</div>'+cats.map(function(c){var info=CAT[c]||{e:"📋",l:c};return'<div class="tab '+(currentCategory===c?"active":"")+'" onclick="setCat(\\''+c+'\\')">'+info.e+' '+info.l+'</div>'}).join("")}
    function setCat(c){currentCategory=c;renderTabs();renderMenu()}
    function renderMenu(){var f=currentCategory==="all"?menuItems:menuItems.filter(function(i){return i.category===currentCategory});var g=document.getElementById("menu-grid");if(!f.length){g.innerHTML='<div class="empty"><div class="empty-icon">🍕</div><div>Nenhum item encontrado</div></div>';return}g.innerHTML=f.map(function(item){var cat=CAT[item.category]||{e:"📋"};var iconHtml=item.image?'<img src="'+item.image+'" style="width:100%;height:100%;object-fit:cover;border-radius:10px" />':'<div style="font-size:28px">'+cat.e+'</div>';return'<div class="menu-item" onclick="openItem(\\''+item.id+'\\')"><div class="menu-icon">'+iconHtml+'</div><div class="menu-info"><div class="menu-name">'+item.name+'</div><div class="menu-desc">'+(item.description||"")+'</div><div class="menu-footer"><div class="menu-price">R$ '+item.price.toFixed(2)+'</div><button class="add-btn" onclick="event.stopPropagation();quickAdd(\\''+item.id+'\\')">+</button></div></div></div>'}).join("")}

    function openItem(id){var item=menuItems.find(function(i){return i.id===id});if(!item)return;selectedItem=item;selectedSize=item.sizes?Object.keys(item.sizes)[0]:null;selectedQty=1;selectedExtras=[];var body=document.getElementById("modal-body");var cat=CAT[item.category]||{e:"📋"};var ss="";if(item.sizes){ss='<div class="size-sel">'+Object.entries(item.sizes).map(function([s,p],i){return'<div class="size-btn '+(i===0?"active":"")+'" onclick="selSize(\\''+s+'\\','+p+',this)"><div class="size-label">'+s+'</div><div class="size-price">R$ '+p.toFixed(2)+'</div></div>'}).join("")+"</div>"}var es="";if(item.extras&&item.extras.length){es='<div style="margin-bottom:16px"><label class="form-label">Adicionais</label><div style="display:flex;flex-direction:column;gap:8px">'+item.extras.map(function(ex,i){return'<label style="display:flex;align-items:center;gap:10px;padding:10px 12px;background:var(--surface-light);border-radius:10px;cursor:pointer;border:1px solid var(--border);transition:all 0.2s" id="extra-'+i+'"><input type="checkbox" onchange="toggleExtra('+i+',\\''+ex.name+'\\','+ex.price+',this.checked)" style="width:18px;height:18px;accent-color:var(--accent)"/><span style="flex:1;font-size:14px;font-weight:500">'+ex.name+'</span><span style="font-size:13px;color:var(--gold);font-weight:600">+R$ '+ex.price.toFixed(2)+'</span></label>'}).join("")+"</div></div>"}body.innerHTML='<div style="text-align:center;font-size:64px;margin-bottom:16px">'+cat.e+'</div><div style="font-size:22px;font-weight:700;margin-bottom:8px">'+item.name+'</div><div style="font-size:14px;color:var(--muted);margin-bottom:16px">'+(item.description||"")+'</div>'+ss+es+'<div class="qty-row"><button class="qty-btn" onclick="changeQty(-1)">−</button><span class="qty-val" id="qty-val">'+selectedQty+'</span><button class="qty-btn" onclick="changeQty(1)">+</button></div><label class="form-label">Observações</label><textarea class="notes" id="item-notes" placeholder="Ex: Sem cebola..."></textarea><button class="add-cart-btn" onclick="addToCart()">Adicionar — R$ <span id="modal-total">'+getItemTotal().toFixed(2)+'</span></button>';document.getElementById("modal-item").classList.add("active")}
    function selSize(s,p,el){selectedSize=s;document.querySelectorAll(".size-btn").forEach(function(b){b.classList.remove("active")});el.classList.add("active");document.getElementById("modal-total").textContent=getItemTotal().toFixed(2)}
    function changeQty(d){selectedQty=Math.max(1,Math.min(99,selectedQty+d));document.getElementById("qty-val").textContent=selectedQty;document.getElementById("modal-total").textContent=getItemTotal().toFixed(2)}
    function toggleExtra(idx,name,price,checked){if(checked){selectedExtras.push({name:name,price:price})}else{selectedExtras=selectedExtras.filter(function(e){return e.name!==name})}document.getElementById("modal-total").textContent=getItemTotal().toFixed(2)}
    function getItemTotal(){if(!selectedItem)return 0;var bp=selectedSize&&selectedItem.sizes?selectedItem.sizes[selectedSize]:selectedItem.price;var ep=selectedExtras.reduce(function(s,e){return s+e.price},0);return(ep+bp)*selectedQty}
    function addToCart(){var notes=document.getElementById("item-notes")?document.getElementById("item-notes").value:"";var price=selectedSize&&selectedItem.sizes?selectedItem.sizes[selectedSize]:selectedItem.price;var extrasTotal=selectedExtras.reduce(function(s,e){return s+e.price},0);cart.push({id:selectedItem.id,name:selectedItem.name,qty:selectedQty,price:price+extrasTotal,size:selectedSize,notes:notes,extras:selectedExtras.length?selectedExtras.slice():[]});selectedExtras=[];updateCartCount();closeModal();showToast(selectedItem.name+" adicionado!")}
    function quickAdd(id){var item=menuItems.find(function(i){return i.id===id});if(!item)return;cart.push({id:item.id,name:item.name,qty:1,price:item.price,size:item.sizes?Object.keys(item.sizes)[0]:null,notes:""});updateCartCount();showToast(item.name+" adicionado!")}
    function updateCartCount(){var c=document.getElementById("cart-count"),t=cart.reduce(function(s,i){return s+i.qty},0);c.textContent=t;c.classList.toggle("hidden",t===0)}
    function closeModal(){document.getElementById("modal-item").classList.remove("active")}
    function closeCart(){document.getElementById("cart-panel").classList.remove("active")}

    function openCart(){var body=document.getElementById("cart-body");if(!cart.length){body.innerHTML='<div class="empty"><div class="empty-icon">🛒</div><div>Carrinho vazio</div></div>';document.getElementById("cart-panel").classList.add("active");return}if(!currentUser){body.innerHTML='<div class="empty"><div class="empty-icon">🔐</div><div>Faça login para finalizar</div><div style="margin-top:16px"><button class="checkout-btn" style="background:var(--accent);width:auto;padding:12px 24px" onclick="openAuth();closeCart()">Entrar ou Cadastrar</button></div></div>';document.getElementById("cart-panel").classList.add("active");return}
    var sub=cart.reduce(function(s,i){return s+i.price*i.qty},0),fee=sub>=80?0:5.90,total=sub+fee;
    body.innerHTML='<div class="cart-items">'+cart.map(function(i,idx){return'<div class="cart-item"><div class="cart-item-info"><div class="cart-item-name">'+i.name+'</div><div class="cart-item-detail">'+(i.size||"")+(i.notes?" • "+i.notes:"")+'</div></div><div class="cart-item-qty"><button class="cart-qty" onclick="cartQty('+idx+',-1)">−</button><span style="font-weight:600">'+i.qty+'</span><button class="cart-qty" onclick="cartQty('+idx+',1)">+</button></div><div class="cart-item-price">R$ '+(i.price*i.qty).toFixed(2)+'</div></div>'}).join("")+'</div><div class="cart-summary"><div class="summary-row"><span style="color:var(--muted)">Subtotal</span><span style="font-weight:600">R$ '+sub.toFixed(2)+'</span></div><div class="summary-row"><span style="color:var(--muted)">Entrega</span><span style="font-weight:600">'+(fee===0?"Grátis!":"R$ "+fee.toFixed(2))+'</span></div>'+(fee===0?'<div style="font-size:11px;color:var(--success);margin-bottom:8px">🎉 Frete grátis acima de R$ 80</div>':'')+'<div class="summary-row total"><span>Total</span><span class="summary-total">R$ '+total.toFixed(2)+'</span></div></div><div style="padding:0 20px 20px"><div class="form-group"><label class="form-label">Nome *</label><input class="form-input" id="cust-name" placeholder="Seu nome" '+(currentUser?'value="'+currentUser.name+'"':"")+' /></div><div class="form-group"><label class="form-label">Telefone *</label><input class="form-input" id="cust-phone" placeholder="(XX) XXXXX-XXXX" maxlength="15" oninput="this.value=maskPhone(this.value)" '+(currentUser?'value="'+maskPhone(currentUser.phone)+'"':"")+' /></div><div class="form-group"><label class="form-label">CEP *</label><div style="display:flex;gap:8px"><input class="form-input" id="cust-cep" placeholder="00000-000" maxlength="9" style="flex:1" oninput="this.value=maskCEP(this.value)" onblur="lookupCEP()" /><button class="btn" onclick="lookupCEP()" style="width:44px;height:44px;flex-shrink:0">🔍</button></div><div id="cep-status" style="font-size:11px;color:var(--muted);margin-top:4px;min-height:16px"></div></div><div class="form-group"><label class="form-label">Rua *</label><input class="form-input" id="cust-street" placeholder="Rua" /></div><div style="display:flex;gap:10px"><div class="form-group" style="flex:0 0 100px"><label class="form-label">Número *</label><input class="form-input" id="cust-number" placeholder="123" /></div><div class="form-group" style="flex:1"><label class="form-label">Complemento</label><input class="form-input" id="cust-complement" placeholder="Apt 101..." /></div></div><div class="form-group"><label class="form-label">Bairro *</label><input class="form-input" id="cust-neighborhood" placeholder="Bairro" /></div><div class="form-group"><label class="form-label">Pagamento *</label><div class="pay-grid">'+PAY.map(function(pm,i){return'<div class="pay-btn '+(i===0?"active":"")+'" onclick="selPay(\\''+pm.k+'\\',this)"><div class="pay-icon">'+pm.i+'</div><div>'+pm.l+'</div></div>'}).join("")+'</div><div id="cash-change-box" class="cash-change"><label>Troco para quanto? (opcional)</label><input type="text" placeholder="Ex: 50,00" oninput="updateCashChange(this.value)" /></div></div><div class="form-group"><label class="form-label">Observações</label><textarea class="notes" id="order-notes" placeholder="Instruções..." rows="2"></textarea></div><button class="checkout-btn" id="checkout-btn" onclick="placeOrder()">Finalizar — R$ '+total.toFixed(2)+'</button></div>';document.getElementById("cart-panel").classList.add("active")}

    function cartQty(i,d){cart[i].qty+=d;if(cart[i].qty<=0)cart.splice(i,1);updateCartCount();if(!cart.length){closeCart();return}openCart()}
    function selPay(m,el){
      selectedPayment=m;
      document.querySelectorAll(".pay-btn").forEach(function(b){b.classList.remove("active")});
      el.classList.add("active");
      var changeBox=document.getElementById("cash-change-box");
      if(changeBox){changeBox.style.display=m==="cash"?"block":"none"}
    }

    function updateCashChange(val){
      cashChangeFor=val?parseFloat(val.replace(",",".")):null;
    }

    async function lookupCEP(){var cep=document.getElementById("cust-cep").value.replace(/\\D/g,"");var st=document.getElementById("cep-status");if(cep.length!==8){st.textContent="Digite 8 dígitos";st.style.color="var(--accent)";return}st.textContent="Buscando...";try{var r=await fetch(API_BASE+"/api/public/address/cep/"+cep);var d=await r.json();if(d.ok){var a=d.address;document.getElementById("cust-street").value=a.street||"";document.getElementById("cust-street").readOnly=true;document.getElementById("cust-street").style.opacity="0.7";document.getElementById("cust-neighborhood").value=a.neighborhood||"";document.getElementById("cust-neighborhood").readOnly=true;document.getElementById("cust-neighborhood").style.opacity="0.7";st.textContent="✓ "+a.street+", "+a.neighborhood+" — "+a.city+"/"+a.state;st.style.color="var(--success)";document.getElementById("cust-number").focus()}else{st.textContent="CEP não encontrado";st.style.color="var(--accent)";document.getElementById("cust-street").readOnly=false;document.getElementById("cust-street").style.opacity="1";document.getElementById("cust-neighborhood").readOnly=false;document.getElementById("cust-neighborhood").style.opacity="1"}}catch(e){st.textContent="Erro ao buscar CEP";st.style.color="var(--accent)"}}

    async function placeOrder(){if(!currentUser){showToast("Faça login para finalizar");openAuth();return}var name=document.getElementById("cust-name").value.trim(),phone=document.getElementById("cust-phone").value.trim(),cep=document.getElementById("cust-cep").value.trim(),street=document.getElementById("cust-street").value.trim(),number=document.getElementById("cust-number").value.trim(),complement=document.getElementById("cust-complement").value.trim(),neighborhood=document.getElementById("cust-neighborhood").value.trim(),notes=document.getElementById("order-notes").value.trim();var addr=street+", "+number+(complement?" - "+complement:"")+(cep?" CEP: "+cep:"");if(!name||!phone||!street||!number||!neighborhood){showToast("Preencha todos os campos obrigatórios");return}if(!cart.length){showToast("Adicione itens ao carrinho");return}
    var btn=document.getElementById("checkout-btn");btn.disabled=true;btn.textContent="Processando...";var items=cart.map(function(i){return{itemId:i.id,name:i.name+(i.size?" ("+i.size+")":""),qty:i.qty,price:i.price,size:i.size,notes:i.notes}});var orderData={customerName:name,customerPhone:phone.replace(/\\D/g,""),customerAddress:addr,customerNeighborhood:neighborhood,items:items,paymentMethod:selectedPayment,notes:notes};if(selectedPayment==="cash"&&cashChangeFor){orderData.cashChangeFor=cashChangeFor}try{var result=await apiPost("/orders",orderData);if(result.ok){cart=[];updateCartCount();closeCart();showSuccess(result.order)}else{showToast(result.error||"Erro");btn.disabled=false;btn.textContent="Finalizar"}}catch(e){showToast("Erro de conexão");btn.disabled=false;btn.textContent="Finalizar"}}

    function showSuccess(o){document.getElementById("view-success").innerHTML='<div class="success"><div class="success-icon">🎉</div><div class="success-title">Pedido Recebido!</div><div class="success-sub">Seu pedido foi enviado com sucesso.</div><div class="success-id">#'+o.id+'</div><div style="display:flex;flex-direction:column;gap:8px;max-width:280px;margin:0 auto"><button class="checkout-btn" onclick="trackOrder(\\''+o.id+'\\')" style="background:var(--accent)"><i class="ph ph-map-pin"></i> Acompanhar</button><button class="checkout-btn" onclick="showView(\\'menu\\')" style="background:var(--surface-light);color:var(--text)">Voltar ao Cardápio</button></div></div>';showView("success")}

    async function trackOrder(id){if(trackingInterval){clearInterval(trackingInterval);trackingInterval=null}lastTrackingStatus=null;document.getElementById("view-tracking").innerHTML='<div class="loading">Carregando...</div>';showView("tracking");var data=await apiGet("/orders/"+id);if(!data.ok){document.getElementById("view-tracking").innerHTML='<div class="error">Pedido não encontrado</div>';return}lastTrackingStatus=data.order.status;renderTracking(data.order);trackingInterval=setInterval(async function(){try{var r=await apiGet("/orders/"+id);if(r.ok&&r.order.status!==lastTrackingStatus){lastTrackingStatus=r.order.status;renderTracking(r.order);showPopup("📦","Status Atualizado!","Pedido #"+id+" — "+STS.find(function(s){return s.k===r.order.status}).l,"var(--success)");playSound([659.25,783.99,987.99],0.2)}}catch(e){}},10000)}
    function renderTracking(o){var ci=STS.findIndex(function(s){return s.k===o.status});var isLast=ci===STS.length-1;document.getElementById("view-tracking").innerHTML='<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px"><h2 style="font-size:18px;font-weight:700">Acompanhar Pedido</h2><button class="btn" onclick="showView(\\'menu\\');if(trackingInterval){clearInterval(trackingInterval);trackingInterval=null}" style="width:auto;padding:8px 16px">← Voltar</button></div><div class="tracking-container"><div class="tracking-id">Pedido <span>#'+o.id+'</span></div><div class="tracking-steps">'+STS.map(function(s,idx){var done=isLast?idx<=ci:idx<ci;var active=!isLast&&idx===ci;return'<div class="tracking-step '+(done?"completed":"")+' '+(active?"active":"")+'"><div class="step-dot">'+(done?"✓":s.i)+'</div><div><div class="step-label">'+s.l+'</div>'+(done?'<div class="step-time">Concluído</div>':'')+(active?'<div class="step-time">Em andamento</div>':'')+'</div></div>'}).join("")+'</div><div class="order-card" style="margin-top:20px"><div class="order-items">'+o.items.map(function(i){return i.qty+"x "+i.name}).join(" • ")+'</div><div class="order-total">Total: R$ '+o.total.toFixed(2)+'</div></div><div style="text-align:center;margin-top:16px;font-size:12px;color:var(--muted)">🔄 Atualizando a cada 10s</div></div>'}

    async function loadMyOrders(){var el=document.getElementById("view-orders");el.innerHTML='<div class="loading">Carregando...</div>';showView("orders");var data=await apiGetAuth("/auth/orders");if(!data.ok){el.innerHTML='<div class="error">Erro ao carregar</div>';return}renderOrdersList(data.orders,el)}
    var _cachedOrders = [];

    function renderOrdersList(orders,el){
      if(!orders.length){
        el.innerHTML='<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px"><h2 style="font-size:18px;font-weight:700">Meus Pedidos</h2><button class="btn" onclick="showView(\\'menu\\')" style="width:auto;padding:8px 16px">← Voltar</button></div><div class="empty"><div class="empty-icon">📭</div><div>Nenhum pedido ainda</div><button class="checkout-btn" onclick="showView(\\'menu\\')" style="margin-top:16px;background:var(--accent)">🍕 Fazer Primeiro Pedido</button></div>';
        return;
      }
      _cachedOrders = orders;
      el.innerHTML='<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px"><h2 style="font-size:18px;font-weight:700">Meus Pedidos</h2><div style="display:flex;gap:8px"><button class="btn" onclick="startNewOrder()" style="width:auto;padding:8px 16px;background:var(--accent)">🍕 Novo Pedido</button><button class="btn" onclick="showView(\\'menu\\')" style="width:auto;padding:8px 16px">← Voltar</button></div></div>'+orders.map(function(o,i){
        var st = (STS.find(function(s){return s.k===o.status})||{}).l||o.status;
        var canRepeat = o.status==='delivered'||o.status==='cancelled';
        var repeatBtn = canRepeat ? '<button class="btn-success" onclick="event.stopPropagation();repeatOrderByIdx('+i+')">🔄 Repetir</button>' : '';
        return '<div class="order-card" onclick="trackOrder(\\''+o.id+'\\')"><div class="order-header"><span class="order-id">#'+o.id+'</span><span class="order-status status-'+o.status+'">'+st+'</span></div><div class="order-items">'+o.items.map(function(x){return x.qty+"x "+x.name}).join(" • ")+'</div><div class="order-total">R$ '+o.total.toFixed(2)+'</div><div class="btns">'+repeatBtn+'<button class="btn-outline" onclick="event.stopPropagation();trackOrder(\\''+o.id+'\\')">📍 Acompanhar</button></div></div>';
      }).join("");
    }

    window.startNewOrder = function() {
      cart = [];
      updateCartCount();
      showView("menu");
    };

    window.repeatOrderByIdx = function(idx) {
      var order = _cachedOrders[idx];
      if (!order || !order.items) return;
      cart = order.items.map(function(item) {
        return {id: item.id, name: item.name, price: item.price, qty: item.qty, size: item.size || ""};
      });
      updateCartCount();
      showPopup("🛒", "Pedido Repetido!", cart.length + " item(s) adicionado(s) ao carrinho", "var(--success)");
      playSound([523.25, 659.25, 783.99], 0.15);
    };

    function showAuthTab(tab){document.getElementById("tab-login").classList.toggle("active",tab==="login");document.getElementById("tab-register").classList.toggle("active",tab==="register");document.getElementById("auth-title").textContent=tab==="login"?"Entrar":"Criar Conta";document.getElementById("auth-sub").textContent=tab==="login"?"Acesse sua conta":"Crie sua conta para acompanhar pedidos";var f=document.getElementById("auth-form");if(tab==="login"){f.innerHTML='<div class="form-group"><label class="form-label">Telefone *</label><input class="form-input" id="auth-phone" placeholder="(XX) XXXXX-XXXX" maxlength="15" oninput="this.value=maskPhone(this.value)" /></div><div class="form-group"><label class="form-label">Senha *</label><input class="form-input" id="auth-password" type="password" placeholder="Sua senha" /></div><button class="checkout-btn" onclick="doLogin()" style="margin-top:8px">Entrar</button><div class="auth-link"><a onclick="showForgotPassword()">Esqueci minha senha</a></div><div class="auth-link">Não tem conta? <a onclick="showAuthTab(\\'register\\')">Cadastre-se</a></div>'}else{f.innerHTML='<div class="form-group"><label class="form-label">Nome *</label><input class="form-input" id="auth-name" placeholder="Seu nome" /></div><div class="form-group"><label class="form-label">Telefone *</label><input class="form-input" id="auth-phone" placeholder="(XX) XXXXX-XXXX" maxlength="15" oninput="this.value=maskPhone(this.value)" /></div><div class="form-group"><label class="form-label">E-mail</label><input class="form-input" id="auth-email" type="email" placeholder="seu@email.com" /></div><div class="form-group"><label class="form-label">Senha *</label><input class="form-input" id="auth-password" type="password" placeholder="Mínimo 4 caracteres" /></div><button class="checkout-btn" onclick="doRegister()" style="margin-top:8px">Criar Conta</button><div class="auth-link">Já tem conta? <a onclick="showAuthTab(\\'login\\')">Entrar</a></div>'}}
    function showForgotPassword(){document.getElementById("auth-title").textContent="Recuperar Senha";document.getElementById("auth-sub").textContent="Informe seu telefone para gerar nova senha";document.getElementById("tab-login").classList.remove("active");document.getElementById("tab-register").classList.remove("active");document.getElementById("auth-form").innerHTML='<div class="form-group"><label class="form-label">Telefone *</label><input class="form-input" id="recovery-phone" placeholder="(XX) XXXXX-XXXX" maxlength="15" oninput="this.value=maskPhone(this.value)" /></div><button class="checkout-btn" onclick="doForgotPassword()" style="margin-top:8px">Gerar Senha Temporária</button><div class="auth-link"><a onclick="showAuthTab(\\'login\\')">← Voltar ao Login</a></div>'}
    function showResetPassword(phone,tempPass){document.getElementById("auth-title").textContent="Nova Senha";document.getElementById("auth-sub").textContent="Senha temporária: <strong>"+tempPass+"</strong><br>Defina sua nova senha:";document.getElementById("auth-sub").innerHTML="Senha temporária: <strong>"+tempPass+"</strong><br>Defina sua nova senha:";document.getElementById("auth-form").innerHTML='<div class="form-group"><label class="form-label">Telefone</label><input class="form-input" value="'+maskPhone(phone)+'" readonly style="opacity:0.7" /></div><div class="form-group"><label class="form-label">Senha Temporária *</label><input class="form-input" id="temp-password" value="'+tempPass+'" readonly style="opacity:0.7" /></div><div class="form-group"><label class="form-label">Nova Senha *</label><input class="form-input" id="new-password" type="password" placeholder="Mínimo 4 caracteres" /></div><div class="form-group"><label class="form-label">Confirmar Senha *</label><input class="form-input" id="confirm-password" type="password" placeholder="Repita a senha" /></div><button class="checkout-btn" onclick="doResetPassword(\\''+phone+'\\',\\''+tempPass+'\\')" style="margin-top:8px">Salvar Nova Senha</button><div class="auth-link"><a onclick="showAuthTab(\\'login\\')">← Voltar ao Login</a></div>'}
    async function doForgotPassword(){var phone=document.getElementById("recovery-phone").value.trim();if(!phone){showToast("Informe seu telefone");return}var r=await apiPost("/auth/forgot-password",{phone:phone.replace(/\\D/g,"")});if(r.ok){showResetPassword(r.phone,r.tempPassword);showToast("Senha temporária gerada!")}else showToast(r.error||"Erro")}
    async function doResetPassword(phone,tempPass){var newPass=document.getElementById("new-password").value;var confirmPass=document.getElementById("confirm-password").value;if(!newPass||!confirmPass){showToast("Preencha todos os campos");return}if(newPass.length<4){showToast("Senha deve ter pelo menos 4 caracteres");return}if(newPass!==confirmPass){showToast("As senhas não coincidem");return}var r=await apiPost("/auth/reset-password",{phone:phone,tempPassword:tempPass,newPassword:newPass});if(r.ok){showToast("Senha alterada com sucesso!");showAuthTab("login")}else showToast(r.error||"Erro")}
    function openAuth(){document.getElementById("auth-overlay").classList.add("active");showAuthTab("login")}
    function closeAuth(){document.getElementById("auth-overlay").classList.remove("active")}
    async function doLogin(){var phone=document.getElementById("auth-phone").value.trim(),pw=document.getElementById("auth-password").value;if(!phone||!pw){showToast("Preencha telefone e senha");return}var r=await apiPost("/auth/login",{phone:phone.replace(/\\D/g,""),password:pw});if(r.ok){authToken=r.token;localStorage.setItem("campy_token",r.token);currentUser=r.user;closeAuth();showToast("Bem-vindo, "+r.name+"!");updateUserMenu()}else showToast(r.error)}
    async function doRegister(){var name=document.getElementById("auth-name").value.trim(),phone=document.getElementById("auth-phone").value.trim(),email=document.getElementById("auth-email").value.trim(),pw=document.getElementById("auth-password").value;if(!name||!phone||!pw){showToast("Preencha nome, telefone e senha");return}if(pw.length<4){showToast("Senha deve ter pelo menos 4 caracteres");return}var r=await apiPost("/auth/register",{name:name,phone:phone.replace(/\\D/g,""),email:email,password:pw});if(r.ok){authToken=r.token;localStorage.setItem("campy_token",r.token);currentUser=r.user;closeAuth();showToast("Conta criada! Bem-vindo, "+r.name+"!");updateUserMenu()}else showToast(r.error)}
    function doLogout(){authToken=null;currentUser=null;localStorage.removeItem("campy_token");updateUserMenu();showToast("Logout realizado");closeUserMenu()}
    function updateUserMenu(){var btn=document.getElementById("btn-user"),menu=document.getElementById("user-menu");if(currentUser){btn.innerHTML='<div class="user-avatar">'+currentUser.name[0]+'</div>';menu.innerHTML='<div style="padding:8px 12px;border-bottom:1px solid var(--border);margin-bottom:4px"><div style="font-weight:600;font-size:14px">'+currentUser.name+'</div><div style="font-size:11px;color:var(--muted)">'+currentUser.phone+'</div></div><div class="user-menu-item" onclick="loadMyOrders();closeUserMenu()">📦 Meus Pedidos</div><div class="user-menu-item" onclick="doLogout()" style="color:var(--accent)">🚪 Sair</div>'}else{btn.innerHTML="👤";menu.innerHTML='<div class="user-menu-item" onclick="openAuth();closeUserMenu()">🔑 Entrar</div><div class="user-menu-item" onclick="showAuthTab(\\'register\\');openAuth();closeUserMenu()">➕ Criar Conta</div>'}}
    function toggleUserMenu(){document.getElementById("user-menu").classList.toggle("active")}
    function closeUserMenu(){document.getElementById("user-menu").classList.remove("active")}

    async function init(){try{var d=await apiGet("/menu");if(d.ok){menuItems=d.items;renderTabs();renderMenu()}}catch(e){document.getElementById("menu-grid").innerHTML='<div class="error">Erro ao carregar cardápio<button onclick="location.reload()" style="margin-top:16px;padding:10px 20px;border-radius:10px;background:var(--accent);color:white;border:none;cursor:pointer">Recarregar</button></div>'}updateCartCount();document.getElementById("btn-cart").onclick=openCart;document.getElementById("btn-orders").onclick=loadMyOrders;document.getElementById("btn-user").onclick=toggleUserMenu;document.getElementById("modal-item").onclick=function(e){if(e.target===e.currentTarget)closeModal()};document.getElementById("cart-panel").onclick=function(e){if(e.target===e.currentTarget)closeCart()};document.addEventListener("click",function(e){if(!e.target.closest("#btn-user")&&!e.target.closest("#user-menu"))closeUserMenu()});if(authToken){try{var r=await apiGetAuth("/auth/me");if(r.ok){currentUser=r.user;startGlobalPolling()}}catch(e){}}updateUserMenu()}

    var globalPollInterval=null;var lastOrderStatuses={};
    function startGlobalPolling(){if(globalPollInterval)return;globalPollInterval=setInterval(function(){if(!currentUser||!authToken)return;checkOrderStatusChanges()},15000)}
    function stopGlobalPolling(){if(globalPollInterval){clearInterval(globalPollInterval);globalPollInterval=null}}
    async function checkOrderStatusChanges(){try{var data=await apiGetAuth("/auth/orders");if(!data.ok||!data.orders)return;data.orders.forEach(function(o){if(o.status==="delivered"||o.status==="cancelled")return;var prev=lastOrderStatuses[o.id];if(prev&&prev!==o.status){var icons={confirmed:"✅",preparing:"👨‍🍳",out_for_delivery:"🛵",delivered:"🎉",cancelled:"❌"};var titles={confirmed:"Pedido Confirmado!",preparing:"Preparando sua pizza!",out_for_delivery:"Saiu para entrega!",delivered:"Pedido Entregue!",cancelled:"Pedido Cancelado"};var colors={confirmed:"#27ae60",preparing:"#f39c12",out_for_delivery:"#3498db",delivered:"#27ae60",cancelled:"#e74c3c"};var labels={confirmed:"confirmado",preparing:"em preparo",out_for_delivery:"saiu para entrega",delivered:"entregue",cancelled:"cancelado"};showPopup(icons[o.status]||"📦",titles[o.status]||"Status Atualizado!","Pedido #"+o.id+"<br>"+(labels[o.status]||""),colors[o.status]||"var(--accent)");playSound([659.25,783.99,987.99],0.2)}lastOrderStatuses[o.id]=o.status})}catch(e){}}
    init();
    
    // Hide splash screen after loading
    setTimeout(function() {
      var splash = document.getElementById('splash');
      if (splash) {
        splash.classList.add('hidden');
        setTimeout(function() { splash.remove(); }, 600);
      }
    }, 2500);
    
    // Register Service Worker for PWA
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/api/public/sw.js').catch(function() {});
    }
  </script>
</body>
</html>`;

app.get("/", (c) => c.html(APP_HTML));
app.get("/menu", (c) => c.html(APP_HTML));

export default app;
