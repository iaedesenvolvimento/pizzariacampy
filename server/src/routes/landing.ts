import { Hono } from "hono";
import { serveStatic } from "hono/bun";

const landing = new Hono();

// Serve the landing page
landing.get("/", (c) => {
  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pizzaria Campy - Pizza Quentinha, Entregue com Rapidez</title>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #0a0a0a;
      --accent: #e94560;
      --gold: #f5a623;
      --surface: #1a1a2e;
      --surface-light: #16213e;
      --text: #ffffff;
      --muted: #8892a4;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Poppins', sans-serif;
      background: var(--primary);
      color: var(--text);
      overflow-x: hidden;
    }
    .header {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      z-index: 100;
      padding: 20px 40px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: rgba(10, 10, 10, 0.95);
      backdrop-filter: blur(20px);
      border-bottom: 1px solid rgba(255,255,255,0.05);
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 24px;
      font-weight: 800;
    }
    .logo-icon {
      width: 45px;
      height: 45px;
      background: linear-gradient(135deg, var(--accent), var(--gold));
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
    }
    .nav-links {
      display: flex;
      gap: 30px;
      list-style: none;
    }
    .nav-links a {
      color: var(--muted);
      text-decoration: none;
      font-size: 14px;
      font-weight: 500;
      transition: color 0.3s;
    }
    .nav-links a:hover { color: var(--text); }
    .btn-primary {
      background: linear-gradient(135deg, var(--accent), #d63851);
      color: white;
      padding: 12px 28px;
      border-radius: 30px;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.3s;
      border: none;
      cursor: pointer;
      font-size: 14px;
    }
    .btn-primary:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 30px rgba(233, 69, 96, 0.4);
    }
    .hero {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      padding: 120px 20px 80px;
      position: relative;
      overflow: hidden;
    }
    .hero::before {
      content: '';
      position: absolute;
      inset: 0;
      background: radial-gradient(ellipse at center, transparent 30%, rgba(233, 69, 96, 0.08) 100%);
    }
    .hero-content {
      position: relative;
      z-index: 1;
      max-width: 800px;
    }
    .hero-badge {
      display: inline-block;
      background: rgba(233, 69, 96, 0.15);
      border: 1px solid rgba(233, 69, 96, 0.3);
      padding: 8px 20px;
      border-radius: 30px;
      font-size: 13px;
      font-weight: 500;
      color: var(--accent);
      margin-bottom: 30px;
    }
    .hero h1 {
      font-size: clamp(40px, 8vw, 80px);
      font-weight: 800;
      line-height: 1.1;
      margin-bottom: 24px;
      background: linear-gradient(135deg, #fff 0%, #ccc 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .hero h1 span {
      background: linear-gradient(135deg, var(--accent), var(--gold));
      -webkit-background-clip: text;
      background-clip: text;
    }
    .hero p {
      font-size: 20px;
      color: var(--muted);
      margin-bottom: 40px;
      line-height: 1.6;
    }
    .hero-buttons {
      display: flex;
      gap: 16px;
      justify-content: center;
      flex-wrap: wrap;
    }
    .btn-secondary {
      background: transparent;
      color: var(--text);
      padding: 14px 32px;
      border-radius: 30px;
      font-weight: 600;
      text-decoration: none;
      border: 2px solid rgba(255,255,255,0.2);
      transition: all 0.3s;
      font-size: 14px;
    }
    .btn-secondary:hover {
      border-color: var(--accent);
      color: var(--accent);
    }
    .features {
      padding: 120px 40px;
      max-width: 1200px;
      margin: 0 auto;
    }
    .section-title {
      text-align: center;
      margin-bottom: 60px;
    }
    .section-title h2 {
      font-size: 42px;
      font-weight: 800;
      margin-bottom: 16px;
    }
    .section-title p {
      color: var(--muted);
      font-size: 18px;
    }
    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 30px;
    }
    .feature-card {
      background: var(--surface);
      border: 1px solid rgba(255,255,255,0.05);
      border-radius: 20px;
      padding: 40px 30px;
      text-align: center;
      transition: all 0.3s;
    }
    .feature-card:hover {
      transform: translateY(-10px);
      border-color: var(--accent);
      box-shadow: 0 20px 40px rgba(0,0,0,0.3);
    }
    .feature-icon {
      width: 80px;
      height: 80px;
      background: linear-gradient(135deg, rgba(233, 69, 96, 0.2), rgba(245, 166, 35, 0.2));
      border-radius: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 36px;
      margin: 0 auto 24px;
    }
    .feature-card h3 {
      font-size: 20px;
      font-weight: 700;
      margin-bottom: 12px;
    }
    .feature-card p {
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
    }
    .stats {
      padding: 80px 40px;
      background: var(--surface);
    }
    .stats-grid {
      max-width: 1000px;
      margin: 0 auto;
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 40px;
      text-align: center;
    }
    .stat-item h3 {
      font-size: 48px;
      font-weight: 800;
      background: linear-gradient(135deg, var(--accent), var(--gold));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .stat-item p {
      color: var(--muted);
      font-size: 14px;
      margin-top: 8px;
    }
    .cta {
      padding: 120px 40px;
      text-align: center;
      position: relative;
    }
    .cta::before {
      content: '';
      position: absolute;
      inset: 0;
      background: radial-gradient(ellipse at center, rgba(233, 69, 96, 0.1) 0%, transparent 70%);
    }
    .cta-content {
      position: relative;
      z-index: 1;
    }
    .cta h2 {
      font-size: 48px;
      font-weight: 800;
      margin-bottom: 20px;
    }
    .cta p {
      color: var(--muted);
      font-size: 18px;
      margin-bottom: 40px;
    }
    .cta-buttons {
      display: flex;
      gap: 16px;
      justify-content: center;
      flex-wrap: wrap;
    }
    .btn-large {
      padding: 18px 40px;
      font-size: 16px;
    }
    .footer {
      padding: 60px 40px 30px;
      border-top: 1px solid rgba(255,255,255,0.05);
    }
    .footer-content {
      max-width: 1200px;
      margin: 0 auto;
      display: grid;
      grid-template-columns: 2fr 1fr 1fr 1fr;
      gap: 40px;
      margin-bottom: 40px;
    }
    .footer-brand h3 {
      font-size: 24px;
      font-weight: 800;
      margin-bottom: 12px;
    }
    .footer-brand p {
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
    }
    .footer-links h4 {
      font-size: 14px;
      font-weight: 600;
      margin-bottom: 16px;
    }
    .footer-links ul {
      list-style: none;
    }
    .footer-links li {
      margin-bottom: 8px;
    }
    .footer-links a {
      color: var(--muted);
      text-decoration: none;
      font-size: 13px;
      transition: color 0.3s;
    }
    .footer-links a:hover { color: var(--accent); }
    .footer-bottom {
      text-align: center;
      padding-top: 30px;
      border-top: 1px solid rgba(255,255,255,0.05);
    }
    .footer-bottom p {
      color: var(--muted);
      font-size: 13px;
    }
    @media (max-width: 768px) {
      .header { padding: 16px 20px; }
      .nav-links { display: none; }
      .hero { padding: 100px 20px 60px; }
      .hero h1 { font-size: 36px; }
      .features { padding: 80px 20px; }
      .section-title h2 { font-size: 28px; }
      .stats-grid { grid-template-columns: repeat(2, 1fr); }
      .stat-item h3 { font-size: 32px; }
      .cta h2 { font-size: 28px; }
      .footer-content { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <header class="header">
    <div class="logo">
      <div class="logo-icon">🍕</div>
      <span>Pizzaria Campy</span>
    </div>
    <nav>
      <ul class="nav-links">
        <li><a href="#home">Início</a></li>
        <li><a href="#features">Vantagens</a></li>
        <li><a href="#testimonials">Depoimentos</a></li>
      </ul>
    </nav>
    <a href="/api/public/app" class="btn-primary">Pedir Agora</a>
  </header>

  <section class="hero" id="home">
    <div class="hero-content">
      <div class="hero-badge">🍕 Delivery Premium</div>
      <h1>Pizza <span>Quentinha</span>, Entregue com <span>Rapidez</span></h1>
      <p>Ingredientes artesanais, massas frescas e uma experiência digital completa. Peça pelo app e acompanhe em tempo real!</p>
      <div class="hero-buttons">
        <a href="/api/public/app" class="btn-primary btn-large">🍕 Fazer Pedido</a>
        <a href="/api/public/app" class="btn-secondary">Ver Cardápio</a>
      </div>
    </div>
  </section>

  <section class="features" id="features">
    <div class="section-title">
      <h2>Por que escolher a Campy?</h2>
      <p>Oferecemos muito mais que pizza — uma experiência completa</p>
    </div>
    <div class="features-grid">
      <div class="feature-card">
        <div class="feature-icon">📱</div>
        <h3>App Próprio</h3>
        <p>Sem comissões de marketplaces. Peça direto pelo nosso app com segurança e praticidade.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">🚀</div>
        <h3>Entrega Rápida</h3>
        <p>Acompanhe seu pedido em tempo real. Do forno até a sua porta, sempre quentinha.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">🧀</div>
        <h3>Ingredientes Premium</h3>
        <p>Mussarela de búfala, molho San Marzano, manjericão fresco. Qualidade que você sente.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">💳</div>
        <h3>Pagamento Flexível</h3>
        <p>PIX, cartão de crédito, débito ou dinheiro. Escolha como prefere pagar.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">🔄</div>
        <h3>Repetir Pedido</h3>
        <p>Gostou? Repita seu pedido favorito com um toque. Seu pedido anterior, pronto em segundos.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">🔔</div>
        <h3>Notificações</h3>
        <p>Receba atualizações em tempo real. Seu pedido sendo preparado, saiu para entrega e mais!</p>
      </div>
    </div>
  </section>

  <section class="stats">
    <div class="stats-grid">
      <div class="stat-item">
        <h3>15min</h3>
        <p>Tempo Médio de Entrega</p>
      </div>
      <div class="stat-item">
        <h3>4.9</h3>
        <p>Avaliação dos Clientes</p>
      </div>
      <div class="stat-item">
        <h3>500+</h3>
        <p>Pedidos Entregues</p>
      </div>
      <div class="stat-item">
        <h3>100%</h3>
        <p>Ingredientes Frescos</p>
      </div>
    </div>
  </section>

  <section class="cta">
    <div class="cta-content">
      <h2>Baixe o App e Ganhe <span style="color: var(--accent);">10% OFF</span></h2>
      <p>Primeiro pedido com desconto. Use o cupom <strong style="color: var(--gold);">CAMPY10</strong></p>
      <div class="cta-buttons">
        <a href="/api/public/app" class="btn-primary btn-large">🍕 Pedir Agora</a>
      </div>
    </div>
  </section>

  <footer class="footer">
    <div class="footer-content">
      <div class="footer-brand">
        <h3>🍕 Pizzaria Campy</h3>
        <p>Pizza quentinha, entregue com rapidez. Ingredientes artesanais e experiência digital completa.</p>
      </div>
      <div class="footer-links">
        <h4>Links</h4>
        <ul>
          <li><a href="#home">Início</a></li>
          <li><a href="#features">Vantagens</a></li>
          <li><a href="#testimonials">Depoimentos</a></li>
        </ul>
      </div>
      <div class="footer-links">
        <h4>App</h4>
        <ul>
          <li><a href="/api/public/app">Fazer Pedido</a></li>
          <li><a href="/api/public/app">Meus Pedidos</a></li>
        </ul>
      </div>
      <div class="footer-links">
        <h4>Contato</h4>
        <ul>
          <li><a href="#">WhatsApp</a></li>
          <li><a href="#">Instagram</a></li>
          <li><a href="#">Facebook</a></li>
        </ul>
      </div>
    </div>
    <div class="footer-bottom">
      <p>© 2026 Pizzaria Campy. Todos os direitos reservados.</p>
    </div>
  </footer>

  <script>
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
          target.scrollIntoView({ behavior: 'smooth' });
        }
      });
    });
  </script>
</body>
</html>`;

  c.header("Content-Type", "text/html; charset=utf-8");
  return c.body(html);
});

export default landing;
