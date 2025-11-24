/* ==========================
   DRAWER LATERAL UNIFICADO
   ========================== */

const drawer = document.getElementById("sideDrawer");
const drawerToggle = document.getElementById("drawerToggle");
const drawerClose = document.getElementById("drawerClose");
const overlay = document.getElementById("drawerOverlay");

function openDrawer() {
  drawer.classList.add("open");
  overlay.classList.add("show");
}

function closeDrawer() {
  drawer.classList.remove("open");
  overlay.classList.remove("show");
}

drawerToggle?.addEventListener("click", openDrawer);
drawerClose?.addEventListener("click", closeDrawer);
overlay?.addEventListener("click", closeDrawer);

/* Fechar com tecla ESC */
document.addEventListener("keydown", e => {
  if (e.key === "Escape") closeDrawer();
});

/* ==========================
   FUNÇÕES DO PAINEL
   ========================== */

window.loadData = async function () {
  try {
    const res = await fetch("data.json?cb=" + Date.now());
    const data = await res.json();

    document.getElementById("filaTotal").textContent = data.total_fila || 0;
    document.getElementById("agendadosTotal").textContent =
      data.agendados_total || 0;

  } catch (e) {
    console.error("Erro ao carregar data.json:", e);
  }
};

// Se estiver na página painel, carregar dados automaticamente
if (document.body.classList.contains("painel")) {
  loadData();
}
