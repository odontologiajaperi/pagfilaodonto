// app.js - comportamento do painel e navegação
// Coloque este arquivo na mesma pasta do painel.html e do data.json

const $ = s => document.querySelector(s);
const $$ = s => Array.from(document.querySelectorAll(s));

/* -----------------------
   Navegação menu (3 pontos)
   ----------------------- */
(function menuSetup(){
  const menuToggle = $('#menuToggle');
  const menuPanel = $('#menuPanel');
  if(menuToggle && menuPanel){
    menuToggle.addEventListener('click', ()=> {
      const open = menuPanel.getAttribute('aria-hidden') === 'false';
      toggleMenu(!open);
    });
    function toggleMenu(show){
      menuPanel.setAttribute('aria-hidden', show ? 'false' : 'true');
      menuToggle.setAttribute('aria-expanded', show ? 'true' : 'false');
    }
    document.addEventListener('click', (e)=> {
      if(!e.target.closest('.menu-wrap')) toggleMenu(false);
    });
    menuPanel.addEventListener('click', (e)=> {
      const btn = e.target.closest('[data-action]');
      if(!btn) return;
      const action = btn.dataset.action;
      if(action === 'goto'){ location.href = btn.dataset.target; }
      if(action === 'refresh'){ loadData(); }
    });
  }
})();

/* -----------------------
   Painel logic (data.json)
   ----------------------- */
let DATA = null;
const nomes=["","jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez"];

/* util: format timestamp */
function stamp(iso){
  try{
    const d=new Date(iso);
    const two=n=>String(n).padStart(2,'0');
    return `${two(d.getDate())}/${two(d.getMonth()+1)}/${d.getFullYear()} ${two(d.getHours())}:${two(d.getMinutes())}`;
  }catch{ return '—' }
}

/* animate numbers */
function animate(el,to){
  if(!el) return;
  const from=Number(el.textContent.replace(/\D/g,''))||0;
  const target=Number(to)||0;
  const diff=target-from;
  const steps=18;
  if(diff===0){ el.textContent = String(target); return; }
  let i=0;
  const tick=()=>{ i++; el.textContent = String(Math.round(from + diff*(i/steps))); if(i<steps) requestAnimationFrame(tick); };
  requestAnimationFrame(tick);
}

/* sort helpers for meses (handles yyyy-mm and month names) */
function parseRank(k){
  const m=/^(\d{4})-(\d{2})(?:-(\d{2}))?$/.exec(k);
  if(m){ const y=+m[1], m1=+m[2], m2=m[3]?+m[3]:null; return y*12 + m1 + (m2?0.5:0); }
  const s=k.toLowerCase();
  if(/fev/.test(s))return 2; if(/mar/.test(s))return 3; if(/mai/.test(s))return 5;
  if(/jun/.test(s))return 6; if(/jul.*ago|jul\/ago|jul-ago/.test(s))return 7.5;
  if(/ago/.test(s))return 8; if(/set/.test(s))return 9; return 0;
}
function labelMes(k){
  const m=/^(\d{4})-(\d{2})(?:-(\d{2}))?$/.exec(k);
  if(m){ const y=m[1], m1=+m[2], m2=m[3]?+m[3]:null; return m2?`${nomes[m1]}+${nomes[m2]}/${y}`:`${nomes[m1]}/${y}`; }
  return k;
}

/* data aggregators */
function getPostos(){ return Object.keys(DATA.postos||{}).sort((a,b)=>a.localeCompare(b,'pt')); }
function getMeses(){ const set=new Set(); for(const p of Object.values(DATA.postos||{})) for(const k of Object.keys(p)) set.add(k); return [...set].sort((a,b)=>parseRank(b)-parseRank(a)); }
function somaPostoMes(p,m){ return Number((DATA.postos?.[p]||{})[m]?.fila||0); }
function somaMesFila(m){ let t=0; for(const p of Object.keys(DATA.postos||{})) t+=somaPostoMes(p,m); return t; }
function somaPostoTodos(p){ let t=0; for(const k of Object.keys(DATA.postos?.[p]||{})) t+=Number(DATA.postos[p][k].fila||0); return t; }
function somaGeralFila(){ let t=0; for(const p of Object.keys(DATA.postos||{})) t+=somaPostoTodos(p); return t; }

/* UI population */
function populaFiltros(){
  const elPosto = $('#postoSelect'), elMes = $('#mesSelect');
  if(!elPosto || !elMes) return;
  elPosto.innerHTML = '';
  const optAll = document.createElement('option'); optAll.value='__ALL__'; optAll.textContent='Todos os postos'; elPosto.appendChild(optAll);
  for(const p of getPostos()){
    const o=document.createElement('option'); o.value = p; o.textContent = p; elPosto.appendChild(o);
  }
  elMes.innerHTML = '';
  for(const m of getMeses()){
    const o=document.createElement('option'); o.value = m; o.textContent = labelMes(m); elMes.appendChild(o);
  }
  // restore from hash if present
  const hash = new URLSearchParams(location.hash.replace(/^#/,''));
  const hp = hash.get('posto'), hm = hash.get('mes');
  elPosto.value = (hp && (hp==='__ALL__' || getPostos().includes(hp)))?hp:'__ALL__';
  elMes.value = (hm && getMeses().includes(hm))?hm:(getMeses()[0]||'');
  atualizaChips();
}

/* chips and url state */
function atualizaChips(){
  const elPosto = $('#postoSelect'), elMes = $('#mesSelect');
  const pillPosto = $('#pillPosto'), pillMes = $('#pillMes'), pillStamp = $('#pillStamp');
  if(pillPosto) pillPosto.textContent = 'Posto: '+(elPosto.value==='__ALL__'?'Todos':elPosto.value);
  if(pillMes) pillMes.textContent = 'Mês: '+labelMes(elMes.value||'—');
  if(pillStamp) pillStamp.textContent = 'Atualizado: '+(DATA?.atualizado_em?stamp(DATA.atualizado_em):'—');
  const p = new URLSearchParams(); p.set('posto', elPosto.value); p.set('mes', elMes.value); history.replaceState(null,'','#'+p.toString());
}

/* render UI */
function render(){
  const elErr = $('#error');
  if(elErr) elErr.style.display='none';
  const posto = $('#postoSelect') ? $('#postoSelect').value : '__ALL__';
  const mes = $('#mesSelect') ? $('#mesSelect').value : null;

  // top numbers
  animate($('#geralAcumFila'), somaGeralFila());
  const ag = Number(DATA?.agendados_total || 0);
  animate($('#agTotal'), ag);
  if($('#homeGeral')) animate($('#homeGeral'), somaGeralFila());
  if($('#homeAg')) $('#homeAg').textContent = String(ag);

  if(!mes){
    if($('#filaMes')) $('#filaMes').textContent='0';
    if($('#filaMesObs')) $('#filaMesObs').textContent='Selecione um mês.';
    if($('#postoAcumFila')) $('#postoAcumFila').textContent='—';
    if($('#postoAcumFilaObs')) $('#postoAcumFilaObs').textContent='Selecione um posto.';
    return;
  }

  // fila do mês
  const filaMes = (posto==='__ALL__') ? somaMesFila(mes) : somaPostoMes(posto, mes);
  animate($('#filaMes'), filaMes);
  if($('#filaMesObs')) $('#filaMesObs').textContent = (posto==='__ALL__') ? 'Somando todos os postos neste mês.' : 'Total deste posto no mês escolhido.';

  // acumulado do posto
  if(posto === '__ALL__'){
    if($('#postoAcumFila')) $('#postoAcumFila').textContent='—';
    if($('#postoAcumFilaObs')) $('#postoAcumFilaObs').textContent='Escolha um posto para ver o total dele.';
  } else {
    const a = somaPostoTodos(posto);
    animate($('#postoAcumFila'), a);
    if($('#postoAcumFilaObs')) $('#postoAcumFilaObs').textContent='Somando todos os meses registrados para este posto.';
  }

  // resumo por posto
  const arr = Object.keys(DATA.postos||{}).map(p=>[p,somaPostoTodos(p)]).sort((a,b)=>b[1]-a[1]);
  const elResumo = $('#postoResumo');
  if(elResumo){
    elResumo.innerHTML = '';
    for(const [name,total] of arr){
      const row = document.createElement('div'); row.className='row';
      row.innerHTML = `<b>${name}</b><span>${total}</span>`;
      elResumo.appendChild(row);
    }
  }

  // fill homeResumo
  const homeResumo = $('#homeResumo');
  if(homeResumo){
    homeResumo.innerHTML = '';
    for(const [name,total] of arr.slice(0,6)){
      const li = document.createElement('li'); li.textContent = `${name}: ${total}`;
      homeResumo.appendChild(li);
    }
  }
}

/* load data.json */
async function loadData(){
  try{
    const res = await fetch(`data.json?cb=${Date.now()}`);
    if(!res.ok) throw new Error(`HTTP ${res.status}`);
    const txt = await res.text();
    try{ DATA = JSON.parse(txt); } catch(e){ throw new Error('JSON inválido: '+e.message); }
    populaFiltros();
    render();
  } catch(e){
    const elErr = $('#error');
    if(elErr){
      elErr.textContent = 'Não foi possível carregar os dados. Verifique se "data.json" está na mesma pasta. Detalhe: '+e.message;
      elErr.style.display = 'block';
    } else {
      console.error('Erro loadData:', e);
    }
  }
}

/* events */
document.addEventListener('change', (e)=>{
  if(!DATA) return;
  if(e.target && (e.target.id === 'postoSelect' || e.target.id === 'mesSelect')){
    atualizaChips();
    render();
  }
});
const refreshBtn = $('#refreshBtn'); if(refreshBtn) refreshBtn.addEventListener('click', loadData);
const refreshMenu = $('#refreshData'); if(refreshMenu) refreshMenu.addEventListener('click', loadData);

/* init */
loadData();
setInterval(loadData, 60000);
