import { Hono } from "hono";

const gerenciar = new Hono();

const HTML = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Gerenciar - Pizzaria Campy</title>
  <link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700&display=swap" rel="stylesheet" />
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Sora',sans-serif;background:#1a1a2e;color:#eef0f2;min-height:100vh;padding:20px}
    .login{max-width:400px;margin:80px auto;text-align:center}
    .logo{font-size:64px;margin-bottom:16px}
    h1{font-size:22px;margin-bottom:8px}
    p{color:#8892a4;font-size:14px;margin-bottom:24px}
    input,select,textarea{width:100%;padding:14px;border-radius:12px;background:#1f2f50;border:1px solid rgba(255,255,255,0.06);color:#eef0f2;font-family:'Sora',sans-serif;font-size:14px;margin-bottom:12px}
    input:focus,select:focus,textarea:focus{outline:none;border-color:#e94560}
    button{padding:14px 24px;border-radius:12px;border:none;font-family:'Sora',sans-serif;font-size:14px;font-weight:600;cursor:pointer}
    .btn-primary{background:#e94560;color:white;width:100%}
    .btn-success{background:#27ae60;color:white}
    .btn-warning{background:#f5a623;color:#1a1a2e}
    .btn-danger{background:#e94560;color:white}
    .btn-outline{background:transparent;border:1px solid #e94560;color:#e94560}
    .btn-secondary{background:#1f2f50;color:#eef0f2;border:1px solid rgba(255,255,255,0.06)}
    button:hover{filter:brightness(1.1)}
    .error{color:#e94560;margin-top:12px;font-size:14px;display:none}
    .panel{display:none;max-width:800px;margin:0 auto}
    .header{display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;padding-bottom:16px;border-bottom:1px solid rgba(255,255,255,0.06)}
    .header h2{font-size:18px}
    .nav{display:flex;gap:8px;margin-bottom:24px;flex-wrap:wrap}
    .nav button{width:auto;padding:10px 16px;border-radius:20px;font-size:12px;background:transparent;border:1px solid rgba(255,255,255,0.06);color:#8892a4}
    .nav button.active{background:#e94560;color:white;border-color:#e94560}
    .refresh-btn{position:fixed;bottom:80px;right:20px;width:48px;height:48px;border-radius:50%;background:#27ae60;border:none;color:white;font-size:20px;cursor:pointer;z-index:100;box-shadow:0 4px 12px rgba(39,174,96,0.4)}
    .refresh-btn:active{transform:scale(0.95)}
    .order{background:#16213e;border-radius:12px;padding:16px;margin-bottom:12px;border:1px solid rgba(255,255,255,0.06)}
    .order-header{display:flex;justify-content:space-between;margin-bottom:8px;flex-wrap:wrap;gap:8px}
    .order-id{font-weight:700;font-size:14px}
    .order-customer{color:#8892a4;font-size:13px;margin-bottom:8px}
    .order-total{font-weight:700;color:#f5a623}
    .badge{padding:4px 10px;border-radius:12px;font-size:11px;font-weight:600}
    .badge-pending{background:rgba(245,166,35,0.2);color:#f5a623}
    .badge-confirmed{background:rgba(100,149,237,0.2);color:cornflowerblue}
    .badge-preparing{background:rgba(233,69,96,0.2);color:#e94560}
    .badge-delivered{background:rgba(39,174,96,0.2);color:#27ae60}
    .badge-cancelled{background:rgba(255,255,255,0.1);color:#8892a4}
    .btns{display:flex;gap:8px;margin-top:12px;flex-wrap:wrap}
    .btns button{width:auto;padding:8px 14px;font-size:12px;border-radius:8px}
    .empty{text-align:center;padding:40px;color:#8892a4}
    .sound-toggle{position:fixed;bottom:20px;right:20px;width:48px;height:48px;border-radius:50%;background:#16213e;border:2px solid rgba(255,255,255,0.06);color:#eef0f2;font-size:20px;cursor:pointer;z-index:100}
    .banner{position:fixed;top:0;left:0;right:0;background:linear-gradient(135deg,#e94560,#c73550);color:white;padding:16px 24px;z-index:1000;display:flex;align-items:center;justify-content:space-between;animation:slideDown 0.3s ease;box-shadow:0 4px 20px rgba(233,69,96,0.5)}
    @keyframes slideDown{from{transform:translateY(-100%);opacity:0}to{transform:translateY(0);opacity:1}}
    .modal{position:fixed;inset:0;background:rgba(0,0,0,0.7);z-index:200;display:none;align-items:center;justify-content:center;backdrop-filter:blur(4px)}
    .modal.active{display:flex}
    .modal-content{background:#16213e;border-radius:16px;padding:24px;width:90%;max-width:500px;max-height:90vh;overflow-y:auto}
    .modal-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px}
    .modal-title{font-size:18px;font-weight:700}
    .form-row{display:flex;gap:12px}
    .form-row input{flex:1}
    .danger-zone{border:2px solid #e94560;border-radius:12px;padding:16px;margin-top:24px}
    .danger-zone h3{color:#e94560;margin-bottom:12px;font-size:16px}
  </style>
</head>
<body>
  <button class="sound-toggle" id="sound-toggle" onclick="toggleSound()">🔔</button>
  <button class="refresh-btn" id="refresh-btn" onclick="manualRefresh()" title="Atualizar">🔄</button>

  <div class="login" id="login-screen">
    <div class="logo">🍕</div>
    <h1>Gerenciar Pizzaria</h1>
    <p>Digite a senha para acessar o painel</p>
    <input type="password" id="pw" placeholder="Senha" />
    <button class="btn-primary" onclick="doLogin()">Entrar</button>
    <div class="error" id="error-msg">Senha incorreta</div>
  </div>

  <div class="panel" id="panel">
    <div class="header">
      <h2>🍕 Pizzaria Campy</h2>
      <button class="btn-secondary" onclick="doLogout()" style="width:auto;padding:8px 16px;font-size:12px">Sair</button>
    </div>
    <div class="nav">
      <button class="active" id="btn-orders" onclick="showOrders()">📦 Pedidos <span id="order-badge" style="background:#e94560;color:white;font-size:10px;padding:2px 6px;border-radius:10px;margin-left:4px;display:none">0</span></button>
      <button id="btn-menu" onclick="showMenu()">🍕 Cardápio</button>
      <button id="btn-settings" onclick="showSettings()">⚙️ Config</button>
      <button onclick="testSound()" style="width:auto;padding:8px 12px;font-size:11px">🔔 Testar Som</button>
      <button onclick="window.open('/api/public/app','_blank')" style="margin-left:auto">Ver App</button>
    </div>
    <div id="content"></div>
  </div>

  <!-- Item Modal -->
  <div class="modal" id="item-modal">
    <div class="modal-content">
      <div class="modal-header">
        <span class="modal-title" id="modal-title">Novo Item</span>
        <button class="btn-secondary" onclick="closeItemModal()" style="width:auto;padding:8px 12px">✕</button>
      </div>
      <input type="hidden" id="edit-item-id" />
      <label style="font-size:12px;color:#8892a4;margin-bottom:4px;display:block">Nome *</label>
      <input type="text" id="item-name" placeholder="Ex: Margherita" />
      <label style="font-size:12px;color:#8892a4;margin-bottom:4px;display:block">Descrição</label>
      <input type="text" id="item-desc" placeholder="Descrição do item" />
      <div class="form-row">
        <div><label style="font-size:12px;color:#8892a4;margin-bottom:4px;display:block">Preço (R$) *</label><input type="number" step="0.01" id="item-price" placeholder="44.90" /></div>
        <div><label style="font-size:12px;color:#8892a4;margin-bottom:4px;display:block">Categoria *</label>
          <select id="item-category"><option value="pizza_classica">🍕 Clássicas</option><option value="pizza_premium">✨ Premium</option><option value="pizza_doce">🍫 Doces</option><option value="bebida">🥤 Bebidas</option><option value="sobremesa">🍰 Sobremesas</option></select>
        </div>
      </div>
      <label style="font-size:12px;color:#8892a4;margin-bottom:8px;display:block">Imagem do Produto</label>
      <div style="display:flex;gap:8px;align-items:center;margin-bottom:8px">
        <div id="image-preview" style="width:80px;height:80px;border-radius:12px;background:#1f2f50;border:2px dashed rgba(255,255,255,0.1);display:flex;align-items:center;justify-content:center;overflow:hidden;flex-shrink:0">
          <span style="font-size:24px;color:#8892a4">📷</span>
        </div>
        <div style="flex:1">
          <input type="file" id="item-image" accept="image/*" onchange="previewImage(this)" style="display:none" />
          <button type="button" onclick="document.getElementById('item-image').click()" style="width:100%;padding:10px;border-radius:8px;background:#1f2f50;border:1px solid rgba(255,255,255,0.1);color:#eef0f2;cursor:pointer;font-size:13px">📁 Escolher Imagem</button>
          <div style="font-size:11px;color:#8892a4;margin-top:4px">JPG, PNG ou WebP (máx. 2MB)</div>
        </div>
      </div>
      <label style="font-size:12px;color:#8892a4;margin-bottom:8px;display:block">Tamanhos</label>
      <div id="sizes-list" style="display:flex;flex-direction:column;gap:6px;margin-bottom:8px"></div>
      <div style="display:flex;gap:6px">
        <input type="text" id="size-name" placeholder="Ex: M, G, GG" style="width:80px;padding:8px;border-radius:8px;background:#1f2f50;border:1px solid rgba(255,255,255,0.06);color:#eef0f2;font-size:13px" />
        <input type="number" step="0.01" id="size-price" placeholder="Preço" style="flex:1;padding:8px;border-radius:8px;background:#1f2f50;border:1px solid rgba(255,255,255,0.06);color:#eef0f2;font-size:13px" />
        <button type="button" onclick="addSizeField()" style="padding:8px 12px;border-radius:8px;background:#27ae60;color:white;border:none;cursor:pointer;font-size:13px">+ Add</button>
      </div>
      <label style="font-size:12px;color:#8892a4;margin-bottom:8px;display:block">Adicionais</label>
      <div id="extras-list" style="display:flex;flex-direction:column;gap:6px;margin-bottom:8px"></div>
      <div style="display:flex;gap:6px">
        <input type="text" id="extra-name" placeholder="Nome do adicional" style="flex:1;padding:8px;border-radius:8px;background:#1f2f50;border:1px solid rgba(255,255,255,0.06);color:#eef0f2;font-size:13px" />
        <input type="number" step="0.01" id="extra-price" placeholder="Preço" style="width:80px;padding:8px;border-radius:8px;background:#1f2f50;border:1px solid rgba(255,255,255,0.06);color:#eef0f2;font-size:13px" />
        <button type="button" onclick="addExtraField()" style="padding:8px 12px;border-radius:8px;background:#27ae60;color:white;border:none;cursor:pointer;font-size:13px">+ Add</button>
      </div>
      <div style="display:flex;gap:8px;margin-top:16px">
        <button class="btn-success" onclick="saveItem()" style="flex:1">Salvar</button>
        <button class="btn-secondary" onclick="closeItemModal()" style="flex:1">Cancelar</button>
      </div>
    </div>
  </div>

  <!-- Confirm Modal -->
  <div class="modal" id="confirm-modal">
    <div class="modal-content" style="text-align:center">
      <div style="font-size:48px;margin-bottom:16px">⚠️</div>
      <h3 id="confirm-title" style="margin-bottom:8px">Tem certeza?</h3>
      <p id="confirm-msg" style="color:#8892a4;margin-bottom:24px">Esta ação não pode ser desfeita.</p>
      <div style="display:flex;gap:8px">
        <button class="btn-danger" onclick="confirmAction()" style="flex:1">Sim, Excluir</button>
        <button class="btn-secondary" onclick="closeConfirmModal()" style="flex:1">Cancelar</button>
      </div>
    </div>
  </div>

  <script>
  (function(){
    var TOKEN = localStorage.getItem("admin_token") || "";
    var API = window.location.origin;
    var lastOrderCount = 0;
    var soundEnabled = true;
    var globalPoll = null;
    var confirmCallback = null;

    var currentAudio = null;

    function playAlert() {
      if (!soundEnabled) return;
      // Stop any currently playing sound first
      if (currentAudio) {
        currentAudio.pause();
        currentAudio.currentTime = 0;
        currentAudio = null;
      }
      // Try to play the uploaded sound file
      try {
        currentAudio = new Audio("/api/public/sounds/notification.mp3");
        currentAudio.volume = 1.0;
        var playPromise = currentAudio.play();
        if (playPromise !== undefined) {
          playPromise.catch(function() {
            playGeneratedBell();
          });
        }
      } catch(e) {
        playGeneratedBell();
      }
    }

    function stopAlert() {
      if (currentAudio) {
        currentAudio.pause();
        currentAudio.currentTime = 0;
        currentAudio = null;
      }
    }

    function playGeneratedBell() {
      try {
        var ctx = new (window.AudioContext || window.webkitAudioContext)();
        if (ctx.state === "suspended") ctx.resume();
        var now = ctx.currentTime;
        // Ding-dong bell
        var notes = [
          { freq: 880, start: 0, dur: 0.4 },
          { freq: 660, start: 0.35, dur: 0.5 }
        ];
        notes.forEach(function(n) {
          var o = ctx.createOscillator();
          var g = ctx.createGain();
          o.connect(g); g.connect(ctx.destination);
          o.type = "sine";
          o.frequency.value = n.freq;
          g.gain.setValueAtTime(0, now + n.start);
          g.gain.linearRampToValueAtTime(0.6, now + n.start + 0.01);
          g.gain.exponentialRampToValueAtTime(0.001, now + n.start + n.dur);
          o.start(now + n.start);
          o.stop(now + n.start + n.dur);
        });
      } catch(e) {}
    }

    function showBanner(order) {
      dismissBanner();
      var d = document.createElement("div");
      d.className = "banner";
      d.id = "order-banner";
      d.innerHTML = '<div><strong>🍕 NOVO PEDIDO!</strong> #' + order.id + ' — ' + order.customerName + ' — R$ ' + order.total.toFixed(2) + '</div><button onclick="dismissBanner()" style="background:rgba(255,255,255,0.2);border:none;color:white;padding:8px 16px;border-radius:8px;cursor:pointer">Fechar</button>';
      document.body.appendChild(d);
      bannerLoopInterval = setInterval(function() {
        if (!document.getElementById("order-banner")) {
          clearInterval(bannerLoopInterval);
          return;
        }
        d.style.animation = "none";
        d.offsetHeight;
        d.style.animation = "slideDown 0.3s ease";
      }, 8000);
    }

    var bannerLoopInterval = null;
    window.dismissBanner = function() {
      if (bannerLoopInterval) { clearInterval(bannerLoopInterval); bannerLoopInterval = null; }
      var banner = document.getElementById("order-banner");
      if (banner) banner.remove();
    };

    window.testSound = function() {
      playAlert();
    };

    function showConfirm(title, msg, callback) {
      document.getElementById("confirm-title").textContent = title;
      document.getElementById("confirm-msg").textContent = msg;
      confirmCallback = callback;
      document.getElementById("confirm-modal").classList.add("active");
    }

    window.confirmAction = function() {
      document.getElementById("confirm-modal").classList.remove("active");
      if (confirmCallback) confirmCallback();
      confirmCallback = null;
    };

    window.closeConfirmModal = function() {
      document.getElementById("confirm-modal").classList.remove("active");
      confirmCallback = null;
    };

    window.doLogin = function() {
      var pw = document.getElementById("pw").value;
      if (!pw) return;
      TOKEN = pw;
      fetch(API + "/api/public/admin/menu", {
        headers: {"X-Admin-Token": TOKEN}
      }).then(function(r) { return r.json(); }).then(function(d) {
        if (d.ok) {
          localStorage.setItem("admin_token", TOKEN);
          document.getElementById("login-screen").style.display = "none";
          document.getElementById("panel").style.display = "block";
          showOrders();
          startGlobalPoll();
          // Initialize order IDs after first load
          setTimeout(function() { checkNewOrders(); }, 1000);
        } else {
          document.getElementById("error-msg").style.display = "block";
          TOKEN = "";
        }
      }).catch(function() {
        document.getElementById("error-msg").textContent = "Erro ao conectar";
        document.getElementById("error-msg").style.display = "block";
      });
    };

    window.doLogout = function() {
      TOKEN = "";
      localStorage.removeItem("admin_token");
      document.getElementById("login-screen").style.display = "block";
      document.getElementById("panel").style.display = "none";
      if (globalPoll) { clearInterval(globalPoll); globalPoll = null; }
      lastOrderIds = [];
    };

    window.showOrders = function() {
      currentTab = "orders";
      document.getElementById("btn-orders").classList.add("active");
      document.getElementById("btn-menu").classList.remove("active");
      document.getElementById("btn-settings").classList.remove("active");
      document.getElementById("content").innerHTML = "<p>Carregando...</p>";
      fetch(API + "/api/public/admin/orders", {
        headers: {"X-Admin-Token": TOKEN}
      }).then(function(r) { return r.json(); }).then(function(d) {
        if (!d.ok) { document.getElementById("content").innerHTML = "<p>Erro ao carregar</p>"; return; }
        var labels = {pending:"Pendente",confirmed:"Confirmado",preparing:"Preparando",out_for_delivery:"Em entrega",delivered:"Entregue",cancelled:"Cancelado"};
        var badges = {pending:"badge-pending",confirmed:"badge-confirmed",preparing:"badge-preparing",out_for_delivery:"badge-confirmed",delivered:"badge-delivered",cancelled:"badge-cancelled"};
        var currentCount = d.orders.filter(function(o) { return o.status === "pending"; }).length;
        if (lastOrderCount > 0 && currentCount > lastOrderCount) { playAlert(); showBanner(d.orders[0]); }
        lastOrderCount = currentCount;
        if (!d.orders.length) { document.getElementById("content").innerHTML = "<div class='empty'>Nenhum pedido</div>"; return; }
        document.getElementById("content").innerHTML = d.orders.map(function(o) {
          var items = o.items.map(function(i) { return i.qty + "x " + i.name; }).join(", ");
          var btns = "";
          if (o.status === "pending") btns += '<button class="btn-success" onclick="updateStatus(\\'' + o.id + '\\',\\'confirmed\\')">✅ Confirmar</button>';
          if (o.status === "confirmed") btns += '<button class="btn-warning" onclick="updateStatus(\\'' + o.id + '\\',\\'preparing\\')">👨‍🍳 Preparar</button>';
          if (o.status === "preparing") btns += '<button class="btn-success" onclick="updateStatus(\\'' + o.id + '\\',\\'out_for_delivery\\')">🛵 Enviar</button>';
          if (o.status === "out_for_delivery") btns += '<button class="btn-success" onclick="updateStatus(\\'' + o.id + '\\',\\'delivered\\')">🎉 Entregue</button>';
          btns += '<button class="btn-outline" onclick="updateStatus(\\'' + o.id + '\\',\\'cancelled\\')">✕ Cancelar</button>';
          return '<div class="order"><div class="order-header"><span class="order-id">#' + o.id + '</span><span class="badge ' + (badges[o.status] || "badge-pending") + '">' + (labels[o.status] || o.status) + '</span></div><div class="order-customer">' + o.customerName + ' — ' + o.customerPhone + '<br>' + items + '</div><div class="order-total">R$ ' + o.total.toFixed(2) + '</div><div class="btns">' + btns + '</div></div>';
        }).join("");
      });
    };

    window.showMenu = function() {
      currentTab = "menu";
      document.getElementById("btn-orders").classList.remove("active");
      document.getElementById("btn-menu").classList.add("active");
      document.getElementById("btn-settings").classList.remove("active");
      document.getElementById("content").innerHTML = '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px"><h3>Cardápio</h3><button class="btn-success" onclick="openItemModal()" style="width:auto;padding:8px 16px;font-size:12px">+ Novo Item</button></div><p>Carregando...</p>';
      fetch(API + "/api/public/admin/menu", {
        headers: {"X-Admin-Token": TOKEN}
      }).then(function(r) { return r.json(); }).then(function(d) {
        if (!d.ok) { document.getElementById("content").innerHTML = "<p>Erro ao carregar</p>"; return; }
        var cats = {pizza_classica:"🍕 Clássicas",pizza_premium:"✨ Premium",pizza_doce:"🍫 Doces",bebida:"🥤 Bebidas",sobremesa:"🍰 Sobremesas"};
        document.getElementById("content").innerHTML = '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px"><h3>Cardápio (' + d.items.length + ' itens)</h3><button class="btn-success" onclick="openItemModal()" style="width:auto;padding:8px 16px;font-size:12px">+ Novo Item</button></div>' + d.items.map(function(i) {
          return '<div class="order" style="display:flex;justify-content:space-between;align-items:center"><div style="flex:1"><div style="font-weight:600">' + i.name + '</div><div style="font-size:12px;color:#8892a4">' + (cats[i.category] || i.category) + ' — R$ ' + i.price.toFixed(2) + (i.available ? '' : ' <span style="color:#e94560">(Oculto)</span>') + '</div></div><div style="display:flex;gap:8px"><button class="btn-secondary" onclick="editItem(\\'' + i.id + '\\')" style="width:auto;padding:6px 10px;font-size:11px">✏️</button><button class="btn-secondary" onclick="toggleItem(\\'' + i.id + '\\')" style="width:auto;padding:6px 10px;font-size:11px">' + (i.available ? "👁️" : "👁️‍🗨️") + '</button><button class="btn-danger" onclick="deleteItem(\\'' + i.id + '\\',\\'' + i.name + '\\')" style="width:auto;padding:6px 10px;font-size:11px">🗑️</button></div></div>';
        }).join("");
      });
    };

    window.showSettings = function() {
      currentTab = "settings";
      document.getElementById("btn-orders").classList.remove("active");
      document.getElementById("btn-menu").classList.remove("active");
      document.getElementById("btn-settings").classList.add("active");
      document.getElementById("content").innerHTML = '<h3 style="margin-bottom:16px">Configurações</h3>' +
        '<div class="danger-zone"><h3>🗑️ Zona de Perigo</h3><p style="color:#8892a4;font-size:13px;margin-bottom:16px">Limpar todos os pedidos da base de dados. Esta ação não pode ser desfeita.</p><button class="btn-danger" onclick="clearAllOrders()" style="width:auto;padding:10px 20px">Limpar Todos os Pedidos</button></div>';
    };

    var extrasData = [];
    var sizesData = [];
    var currentImageData = null;

    window.previewImage = function(input) {
      var file = input.files[0];
      if (!file) return;
      if (file.size > 2 * 1024 * 1024) { alert("Imagem muito grande (máx. 2MB)"); return; }
      var reader = new FileReader();
      reader.onload = function(e) {
        currentImageData = e.target.result;
        document.getElementById("image-preview").innerHTML = '<img src="'+e.target.result+'" style="width:100%;height:100%;object-fit:cover" />';
      };
      reader.readAsDataURL(file);
    };

    window.addSizeField = function() {
      var name = document.getElementById("size-name").value.trim();
      var price = parseFloat(document.getElementById("size-price").value);
      if (!name || isNaN(price)) { alert("Preencha nome e preço do tamanho"); return; }
      sizesData.push({ name: name, price: price });
      renderSizesList();
      document.getElementById("size-name").value = "";
      document.getElementById("size-price").value = "";
    };

    window.removeSizeField = function(idx) {
      sizesData.splice(idx, 1);
      renderSizesList();
    };

    function renderSizesList() {
      var el = document.getElementById("sizes-list");
      el.innerHTML = sizesData.map(function(s, i) {
        return '<div style="display:flex;align-items:center;gap:8px;padding:6px 10px;background:#1f2f50;border-radius:8px;border:1px solid rgba(255,255,255,0.06)"><span style="font-size:13px;font-weight:600">'+s.name+'</span><span style="flex:1"></span><span style="font-size:12px;color:#f5a623">R$ '+s.price.toFixed(2)+'</span><button onclick="removeSizeField('+i+')" style="background:none;border:none;color:#e94560;cursor:pointer;font-size:16px">✕</button></div>';
      }).join("");
    }

    window.addExtraField = function() {
      var name = document.getElementById("extra-name").value.trim();
      var price = parseFloat(document.getElementById("extra-price").value);
      if (!name || isNaN(price)) { alert("Preencha nome e preço do adicional"); return; }
      extrasData.push({ name: name, price: price });
      renderExtrasList();
      document.getElementById("extra-name").value = "";
      document.getElementById("extra-price").value = "";
    };

    window.removeExtraField = function(idx) {
      extrasData.splice(idx, 1);
      renderExtrasList();
    };

    function renderExtrasList() {
      var el = document.getElementById("extras-list");
      el.innerHTML = extrasData.map(function(ex, i) {
        return '<div style="display:flex;align-items:center;gap:8px;padding:6px 10px;background:#1f2f50;border-radius:8px;border:1px solid rgba(255,255,255,0.06)"><span style="flex:1;font-size:13px">'+ex.name+'</span><span style="font-size:12px;color:#f5a623">R$ '+ex.price.toFixed(2)+'</span><button onclick="removeExtraField('+i+')" style="background:none;border:none;color:#e94560;cursor:pointer;font-size:16px">✕</button></div>';
      }).join("");
    }

    window.openItemModal = function(id) {
      document.getElementById("edit-item-id").value = "";
      document.getElementById("modal-title").textContent = "Novo Item";
      document.getElementById("item-name").value = "";
      document.getElementById("item-desc").value = "";
      document.getElementById("item-price").value = "";
      document.getElementById("item-category").value = "pizza_classica";
      extrasData = [];
      sizesData = [];
      currentImageData = null;
      document.getElementById("image-preview").innerHTML = '<span style="font-size:24px;color:#8892a4">📷</span>';
      document.getElementById("item-image").value = "";
      renderExtrasList();
      renderSizesList();
      document.getElementById("item-modal").classList.add("active");
    };

    window.editItem = function(id) {
      fetch(API + "/api/public/admin/menu", { headers: {"X-Admin-Token": TOKEN} })
        .then(function(r) { return r.json(); })
        .then(function(d) {
          var item = d.items.find(function(i) { return i.id === id; });
          if (!item) return;
          document.getElementById("edit-item-id").value = id;
          document.getElementById("modal-title").textContent = "Editar Item";
          document.getElementById("item-name").value = item.name;
          document.getElementById("item-desc").value = item.description || "";
          document.getElementById("item-price").value = item.price;
          document.getElementById("item-category").value = item.category;
          extrasData = item.extras ? item.extras.slice() : [];
          sizesData = item.sizes ? Object.entries(item.sizes).map(function([k,v]) { return {name:k, price:v}; }) : [];
          currentImageData = item.image || null;
          if (item.image) {
            document.getElementById("image-preview").innerHTML = '<img src="'+item.image+'" style="width:100%;height:100%;object-fit:cover" />';
          } else {
            document.getElementById("image-preview").innerHTML = '<span style="font-size:24px;color:#8892a4">📷</span>';
          }
          document.getElementById("item-image").value = "";
          renderExtrasList();
          renderSizesList();
          document.getElementById("item-modal").classList.add("active");
        });
    };

    window.closeItemModal = function() {
      document.getElementById("item-modal").classList.remove("active");
    };

    window.saveItem = function() {
      var id = document.getElementById("edit-item-id").value;
      var name = document.getElementById("item-name").value.trim();
      var desc = document.getElementById("item-desc").value.trim();
      var price = document.getElementById("item-price").value;
      var cat = document.getElementById("item-category").value;
      if (!name || !price) { alert("Nome e preço são obrigatórios"); return; }
      var sizes = sizesData.length ? {} : null;
      if (sizesData.length) { sizesData.forEach(function(s) { sizes[s.name] = s.price; }); }
      var extras = extrasData.length ? extrasData : null;
      var data = { name: name, description: desc, price: parseFloat(price), category: cat, sizes: sizes, toppings: null, extras: extras, image: currentImageData };
      var url = id ? API + "/api/public/admin/menu/" + id : API + "/api/public/admin/menu";
      var method = id ? "PUT" : "POST";
      fetch(url, {
        method: method,
        headers: {"Content-Type": "application/json", "X-Admin-Token": TOKEN},
        body: JSON.stringify(data)
      }).then(function() { closeItemModal(); showMenu(); });
    };

    window.toggleItem = function(id) {
      fetch(API + "/api/public/admin/menu/" + id + "/toggle", {
        method: "PATCH",
        headers: {"X-Admin-Token": TOKEN}
      }).then(function() { showMenu(); });
    };

    window.deleteItem = function(id, name) {
      showConfirm("Excluir Item", "Excluir " + name + " do cardápio?", function() {
        fetch(API + "/api/public/admin/menu/" + id, {
          method: "DELETE",
          headers: {"X-Admin-Token": TOKEN}
        }).then(function() { showMenu(); });
      });
    };

    window.updateStatus = function(id, status) {
      stopAlert();
      dismissBanner();
      fetch(API + "/api/public/admin/orders/" + id + "/status", {
        method: "PATCH",
        headers: {"Content-Type": "application/json", "X-Admin-Token": TOKEN},
        body: JSON.stringify({status: status})
      }).then(function() { showOrders(); });
    };

    window.clearAllOrders = function() {
      showConfirm("Limpar Pedidos", "Excluir TODOS os pedidos? Esta ação não pode ser desfeita!", function() {
        fetch(API + "/api/public/admin/orders", {
          method: "DELETE",
          headers: {"X-Admin-Token": TOKEN}
        }).then(function() { showSettings(); alert("Pedidos limpos!"); });
      });
    };

    window.toggleSound = function() {
      soundEnabled = !soundEnabled;
      document.getElementById("sound-toggle").textContent = soundEnabled ? "🔔" : "🔕";
    };

    var currentTab = "orders";
    var globalPoll = null;
    var lastPendingCount = -1;

    window.manualRefresh = function() {
      var btn = document.getElementById("refresh-btn");
      btn.style.transform = "rotate(360deg)";
      btn.style.transition = "transform 0.5s";
      setTimeout(function() { btn.style.transform = "rotate(0deg)"; }, 500);
      if (currentTab === "orders") showOrders();
      else if (currentTab === "menu") showMenu();
      else if (currentTab === "settings") showSettings();
    };

    function startGlobalPoll() {
      if (globalPoll) return;
      globalPoll = setInterval(function() {
        if (TOKEN) checkNewOrders();
      }, 5000);
    }

    function checkNewOrders() {
      fetch(API + "/api/public/admin/orders", {
        headers: {"X-Admin-Token": TOKEN}
      }).then(function(r) { return r.json(); }).then(function(d) {
        if (!d.ok || !d.orders) return;
        
        var pendingCount = d.orders.filter(function(o) { return o.status === "pending"; }).length;
        
        // Update badge
        var badge = document.getElementById("order-badge");
        if (badge) {
          badge.textContent = pendingCount;
          badge.style.display = pendingCount > 0 ? "flex" : "none";
        }
        
        // First run - just set the count, don't play sound
        if (lastPendingCount === -1) {
          lastPendingCount = pendingCount;
          return;
        }
        
        // New orders detected!
        if (pendingCount > lastPendingCount) {
          playAlert();
          // Find the newest pending order
          var newestPending = d.orders.filter(function(o) { return o.status === "pending"; })[0];
          if (newestPending) showBanner(newestPending);
        }
        
        lastPendingCount = pendingCount;
      }).catch(function() {});
    }

    if (TOKEN) {
      document.getElementById("pw").value = TOKEN;
      doLogin();
    }
  })();
  </script>
</body>
</html>`;

gerenciar.get("/", (c) => {
  c.header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
  c.header("Pragma", "no-cache");
  c.header("Expires", "0");
  return c.html(HTML);
});

export default gerenciar;
