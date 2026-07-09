import { Hono } from "hono";

const admin = new Hono();

const ADMIN_HTML = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Admin - Pizzaria Campy</title>
  <link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700&display=swap" rel="stylesheet" />
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Sora',sans-serif;background:#1a1a2e;color:#eef0f2;min-height:100vh;padding:20px}
    .login{max-width:400px;margin:100px auto;text-align:center}
    .logo{font-size:64px;margin-bottom:16px}
    h1{font-size:24px;margin-bottom:8px}
    p{color:#8892a4;font-size:14px;margin-bottom:24px}
    input{width:100%;padding:16px;border-radius:12px;background:#1f2f50;border:1px solid rgba(255,255,255,0.06);color:#eef0f2;font-family:'Sora',sans-serif;font-size:16px;margin-bottom:16px}
    input:focus{outline:none;border-color:#e94560}
    button{width:100%;padding:16px;border-radius:12px;border:none;font-family:'Sora',sans-serif;font-size:16px;font-weight:600;cursor:pointer;background:#e94560;color:white}
    button:hover{filter:brightness(1.1)}
    .error{color:#e94560;margin-top:12px;font-size:14px;display:none}
    .success{color:#27ae60;margin-top:12px;font-size:14px;display:none}
    .panel{display:none;max-width:800px;margin:0 auto}
    .header{display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;padding-bottom:16px;border-bottom:1px solid rgba(255,255,255,0.06)}
    .header h2{font-size:20px}
    .nav{display:flex;gap:8px;margin-bottom:24px}
    .nav button{width:auto;padding:10px 20px;border-radius:20px;font-size:13px;background:transparent;border:1px solid rgba(255,255,255,0.06);color:#8892a4}
    .nav button.active{background:#e94560;color:white;border-color:#e94560}
    .order{background:#16213e;border-radius:12px;padding:16px;margin-bottom:12px;border:1px solid rgba(255,255,255,0.06)}
    .order-header{display:flex;justify-content:space-between;margin-bottom:8px}
    .order-id{font-weight:700}
    .order-customer{color:#8892a4;font-size:14px;margin-bottom:8px}
    .order-total{font-weight:700;color:#f5a623}
    .badge{padding:4px 10px;border-radius:12px;font-size:11px;font-weight:600}
    .badge-pending{background:rgba(245,166,35,0.2);color:#f5a623}
    .badge-confirmed{background:rgba(100,149,237,0.2);color:cornflowerblue}
    .badge-preparing{background:rgba(233,69,96,0.2);color:#e94560}
    .badge-delivered{background:rgba(39,174,96,0.2);color:#27ae60}
    .btns{display:flex;gap:8px;margin-top:12px;flex-wrap:wrap}
    .btns button{width:auto;padding:8px 14px;font-size:12px;border-radius:8px}
    .btns .btn-success{background:#27ae60}
    .btns .btn-warning{background:#f5a623;color:#1a1a2e}
    .btns .btn-danger{background:#e94560}
    .btns .btn-outline{background:transparent;border:1px solid #e94560;color:#e94560}
    .empty{text-align:center;padding:40px;color:#8892a4}
  </style>
</head>
<body>
  <div class="login" id="login-screen">
    <div class="logo">🍕</div>
    <h1>Admin Pizzaria Campy</h1>
    <p>Digite a senha para acessar</p>
    <input type="password" id="pw" placeholder="Senha" />
    <button onclick="login()">Entrar</button>
    <div class="error" id="error-msg">Senha incorreta</div>
  </div>

  <div class="panel" id="panel">
    <div class="header">
      <h2>🍕 Painel Admin</h2>
      <button onclick="logout()" style="width:auto;padding:8px 16px;font-size:12px">Sair</button>
    </div>
    <div class="nav">
      <button class="active" id="btn-orders" onclick="showOrders()">📦 Pedidos</button>
      <button id="btn-menu" onclick="showMenu()">🍕 Cardápio</button>
      <button onclick="window.open('/api/public/app','_blank')" style="margin-left:auto">Ver App</button>
    </div>
    <div id="content"></div>
  </div>

  <script>
    var TOKEN = localStorage.getItem("admin_token") || "";
    var API = window.location.origin;

    function login() {
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
        } else {
          document.getElementById("error-msg").style.display = "block";
          TOKEN = "";
        }
      }).catch(function() {
        document.getElementById("error-msg").textContent = "Erro ao conectar";
        document.getElementById("error-msg").style.display = "block";
      });
    }

    function logout() {
      TOKEN = "";
      localStorage.removeItem("admin_token");
      document.getElementById("login-screen").style.display = "block";
      document.getElementById("panel").style.display = "none";
    }

    function showOrders() {
      document.getElementById("btn-orders").classList.add("active");
      document.getElementById("btn-menu").classList.remove("active");
      document.getElementById("content").innerHTML = "<p>Carregando...</p>";
      fetch(API + "/api/public/admin/orders", {
        headers: {"X-Admin-Token": TOKEN}
      }).then(function(r) { return r.json(); }).then(function(d) {
        if (!d.ok) { document.getElementById("content").innerHTML = "<p>Erro ao carregar</p>"; return; }
        var labels = {pending:"Pendente",confirmed:"Confirmado",preparing:"Preparando",out_for_delivery:"Em entrega",delivered:"Entregue",cancelled:"Cancelado"};
        var badges = {pending:"badge-pending",confirmed:"badge-confirmed",preparing:"badge-preparing",out_for_delivery:"badge-confirmed",delivered:"badge-delivered",cancelled:"badge-pending"};
        if (!d.orders.length) { document.getElementById("content").innerHTML = "<div class='empty'>Nenhum pedido</div>"; return; }
        document.getElementById("content").innerHTML = d.orders.map(function(o) {
          var items = o.items.map(function(i) { return i.qty + "x " + i.name; }).join(", ");
          var btns = "";
          if (o.status === "pending") btns += '<button class="btn-success" onclick="updateStatus(\'' + o.id + '\',\'confirmed\')">✅ Confirmar</button>';
          if (o.status === "confirmed") btns += '<button class="btn-warning" onclick="updateStatus(\'' + o.id + '\',\'preparing\')">👨‍🍳 Preparar</button>';
          if (o.status === "preparing") btns += '<button class="btn-success" onclick="updateStatus(\'' + o.id + '\',\'out_for_delivery\')">🛵 Enviar</button>';
          if (o.status === "out_for_delivery") btns += '<button class="btn-success" onclick="updateStatus(\'' + o.id + '\',\'delivered\')">🎉 Entregue</button>';
          btns += '<button class="btn-outline" onclick="updateStatus(\'' + o.id + '\',\'cancelled\')">✕ Cancelar</button>';
          return '<div class="order"><div class="order-header"><span class="order-id">#' + o.id + '</span><span class="badge ' + (badges[o.status] || "badge-pending") + '">' + (labels[o.status] || o.status) + '</span></div><div class="order-customer">' + o.customerName + ' — ' + o.customerPhone + '<br>' + items + '</div><div class="order-total">R$ ' + o.total.toFixed(2) + '</div><div class="btns">' + btns + '</div></div>';
        }).join("");
      });
    }

    function showMenu() {
      document.getElementById("btn-orders").classList.remove("active");
      document.getElementById("btn-menu").classList.add("active");
      document.getElementById("content").innerHTML = "<p>Carregando...</p>";
      fetch(API + "/api/public/admin/menu", {
        headers: {"X-Admin-Token": TOKEN}
      }).then(function(r) { return r.json(); }).then(function(d) {
        if (!d.ok) { document.getElementById("content").innerHTML = "<p>Erro ao carregar</p>"; return; }
        var cats = {pizza_classica:"🍕 Clássicas",pizza_premium:"✨ Premium",pizza_doce:"🍫 Doces",bebida:"🥤 Bebidas",sobremesa:"🍰 Sobremesas"};
        document.getElementById("content").innerHTML = '<h3 style="margin-bottom:16px">Cardápio (' + d.items.length + ' itens)</h3>' + d.items.map(function(i) {
          return '<div class="order" style="display:flex;justify-content:space-between;align-items:center"><div><div style="font-weight:600">' + i.name + '</div><div style="font-size:12px;color:#8892a4">' + (cats[i.category] || i.category) + ' — R$ ' + i.price.toFixed(2) + '</div></div><button class="btn-outline" style="width:auto;padding:6px 12px;font-size:11px" onclick="toggleItem(\'' + i.id + '\')">' + (i.available ? "Ocultar" : "Mostrar") + '</button></div>';
        }).join("");
      });
    }

    function updateStatus(id, status) {
      fetch(API + "/api/public/admin/orders/" + id + "/status", {
        method: "PATCH",
        headers: {"Content-Type": "application/json", "X-Admin-Token": TOKEN},
        body: JSON.stringify({status: status})
      }).then(function() { showOrders(); });
    }

    function toggleItem(id) {
      fetch(API + "/api/public/admin/menu/" + id + "/toggle", {
        method: "PATCH",
        headers: {"X-Admin-Token": TOKEN}
      }).then(function() { showMenu(); });
    }

    if (TOKEN) {
      document.getElementById("pw").value = TOKEN;
      login();
    }
  </script>
</body>
</html>`;

admin.get("/", (c) => {
  c.header("Cache-Control", "no-store, no-cache, must-revalidate");
  c.header("Pragma", "no-cache");
  c.header("Expires", "0");
  return c.html(ADMIN_HTML);
});
admin.get("/panel", (c) => {
  c.header("Cache-Control", "no-store, no-cache, must-revalidate");
  c.header("Pragma", "no-cache");
  c.header("Expires", "0");
  return c.html(ADMIN_HTML);
});
admin.get("/painel", (c) => {
  c.header("Cache-Control", "no-store, no-cache, must-revalidate");
  c.header("Pragma", "no-cache");
  c.header("Expires", "0");
  return c.html(ADMIN_HTML);
});
admin.get("/dashboard", (c) => {
  c.header("Cache-Control", "no-store, no-cache, must-revalidate");
  c.header("Pragma", "no-cache");
  c.header("Expires", "0");
  return c.html(ADMIN_HTML);
});

export default admin;
