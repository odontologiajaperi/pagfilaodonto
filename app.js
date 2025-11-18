// app.js - comportamento do painel e navegação
// colar na mesma pasta e referenciar no index.html

const $ = s => document.querySelector(s);
const $$ = s => Array.from(document.querySelectorAll(s));

/* Navegação entre views */
function showView(id){
  // toggle tabs
  $$('.tabbtn').forEach(b => b.classList.toggle('active', b.dataset.view === id));
  // show/hide views
  $$('.view').forEach(v => v.classList.toggle('active', v.id === id));
  // set menu hidden if open
  toggleMenu(false);
}
$$('.tabbtn').forEach(b => b.addEventListener('click', ()=> showView(b.dataset.view)));

/* Menu 3 pontos */
const menuToggle = $('#menuToggle'), menuPanel = $('#menuPanel');
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
  if(action === 'goto'){
    showView(btn.dataset.target);
  }
});

/* hooks dos itens customizados */
$('#refreshData').addEventListener('click', ()=> loadData());
$('#refreshBtn').addEventListener('click', ()=> loadData());

/* ---------------------------
   Painel: carregamento dos dados
   --------------------------- */
let DATA = null;
const nomes = ["","jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez"];

function stamp(iso){
  try{const d=new Date(iso);const two=n=>String(n).padStart(2,'0');return `${two(d.getDate())}/${two(d.getMonth()+1)}/${d.getFullYear()} ${two(d.getHours())}:${two(d.getMinutes())}`;}
  catch{return '—'}
}
function animate(el,to){
  const from=Number(el.textContent.replace(/\D/g,''))||0;
  const target=Number(to)||0;
  const diff=target-from;
  const steps=18;
  if(diff===0){el.textContent=String(target);return;}
  let i=0;
  const tick=()=>{i++;el.textContent=String(Math.round(from+diff*(i/steps)));if(i<steps)requestAnimationFrame(tick);};
  requestAnimationFrame(tick);
}

function parseRank(k){
  const m=/^(\d{4})-(\d{2})(?:-(\d{2}))?$/.exec(k);
  if(m){const y=+m[1], m1=+m[2], m2=m[3]?+m[3]:null;return y*12+m1+(m2?0.5:0);}
  const s=k.toLowerCase();
  if(/fev/.test(s))return 2; if(/mar/.test(s))return 3; if(/mai/.test(s))return 5;
  if(/jun/.test(s))return 6; if(/jul.*ago|jul\/ago|jul-ago/.test(s))return 7.5;
  if(/ago/.test(s))return 8; if(/set/.test(s))return 9; return 0;
}
function labelMes(k){
  const m=/^(\d{4})-(\d{2})(?:-(\d{2}))?$/.exec(k);
  if(m){const y=m[1], m1=+m[2], m2=m[3]?+m[3]:null;return m2?`${nomes[m1]}+${nomes[m2]}/${y}`:`${nomes[m1]}/${y}`;}
  return k;
}

/* soma utilitárias */
function getPostos(){ return Object.keys(DATA.postos||{}).sort((a,b)=>a.localeCompare(b,'pt')); }
function getMeses(){ const set=new Set(); for(const p of Object.values(DATA.postos||{})) for(const k of Object.keys(p)) set.add(k); return [...set].sort((a,b)=>parseRank(b)-parseRank(a)); }
function somaPostoMes(p,m){ return Number((DATA.postos?.[p]||{})[m]?.fila||0); }
function somaMesFila(m){ let t=0; for(const p of Object.keys(DATA.postos||{})) t+=somaPostoMes(p,m); return t; }
function somaPostoTodos(p){ let t=0; for(const k of Object.keys(DATA.postos?.[p]||{})) t+=Number(DATA.postos[p][k].fila||0); return t; }
function somaGeralFila(){ let t=0; for(const p of Object.keys(DATA.postos||{})) t+=somaPostoTodos(p); return t; }

/* popula filtros e UI */
function populaFiltros(){
  const elPosto = $('#postoSelect'), elMes = $('#mesSelect');
  elPosto.innerHTML = '<option value="__ALL__">Todos os postos</option>';
  for(const p of getPostos()){
    const o = document.createElement('option'); o.value = p; o.textContent = p; elPosto.appendChild(o);
  }
  elMes.innerHTML = '';
  for(const m of getMeses()){
    const o = document.createElement('option'); o.value = m; o.textContent = labelMes(m); elMes.appendChild(o);
  }
  // restore hash params if present
  const hash = new URLSearchParams(location.hash.replace(/^#/,''));
  const hp = hash.get('posto'), hm = hash.get('mes');
  elPosto.value = (hp && (hp==='__ALL__' || getPostos().includes(hp)))?hp:'__ALL__';
  elMes.value = (hm && getMeses().includes(hm))?hm:(getMeses()[0]||'');
  atualizaChips();
}
function atualizaChips(){
  $('#pillPosto').textContent = 'Posto: '+($('#postoSelect').value==='__ALL__' ? 'Todos' : $('#postoSelect').value);
  $('#pillMes').textContent = 'Mês: '+ labelMes($('#mesSelect').value||'—');
  $('#pillStamp').textContent = 'Atualizado: ' + (DATA?.atualizado_em ? stamp(DATA.atualizado_em) : '—');
  const p = new URLSearchParams(); p.set('posto',$('#postoSelect').value); p.set('mes',$('#mesSelect').value); history.replaceState(null,'','#'+p.toString());
}

/* render painel */
function render(){
  $('#error').style.display='none';
  const posto = $('#postoSelect').value, mes = $('#mesSelect').value;

  animate($('#geralAcumFila'), somaGeralFila());
  animate($('#homeGeral'), somaGeralFila());
  animate($('#agTotal'), Number(DATA.agendados_total || 0));
  $('#homeAg').textContent = Number(DATA.agendados_total || 0);

  if(!mes){
    $('#filaMes').textContent='0';
    $('#filaMesObs').textContent='Selecione um mês.';
    $('#postoAcumFila').textContent='—';
    $('#postoAcumFilaObs').textContent='Selecione um posto.';
    return;
  }

  const filaMes = (posto==='__ALL__') ? somaMesFila(mes) : somaPostoMes(posto, mes);
  animate($('#filaMes'), filaMes);
  $('#filaMesObs').textContent = (posto==='__ALL__') ? 'Somando todos os postos neste mês.' : 'Total deste posto no mês escolhido.';

  if(posto==='__ALL__'){
    $('#postoAcumFila').textContent='—';
    $('#postoAcumFilaObs').textContent='Escolha um posto para ver o total dele.';
  } else {
    const a = somaPostoTodos(posto);
    animate($('#postoAcumFila'), a);
    $('#postoAcumFilaObs').textContent = 'Somando todos os meses registrados para este posto.';
  }

  // resumo por posto
  const arr = Object.keys(DATA.postos||{}).map(p=>[p,somaPostoTodos(p)]).sort((a,b)=>b[1]-a[1]);
  const elResumo = $('#postoResumo');
  elResumo.innerHTML = '';
  for(const [name,total] of arr){
    const row = document.createElement('div'); row.className='row';
    row.innerHTML = `<b>${name}</b><span>${total}</span>`;
    elResumo.appendChild(row);
  }

  // preenchimento homeResumo
  const homeResumo = $('#homeResumo');
  homeResumo.innerHTML = '';
  for(const [name,total] of arr.slice(0,6)){
    const li = document.createElement('li'); li.textContent = `${name}: ${total}`;
    homeResumo.appendChild(li);
  }
}

/* Carrega data.json */
async function loadData(){
  try{
    const res = await fetch(`data.json?cb=${Date.now()}`);
    if(!res.ok) throw new Error(`HTTP ${res.status}`);
    const txt = await res.text();
    try{ DATA = JSON.parse(txt); } catch(e){ throw new Error('JSON inválido: '+e.message) }
    populaFiltros();
    render();
  } catch(e){
    $('#error').textContent = 'Não foi possível carregar os dados. Verifique se "data.json" está na mesma pasta. Detalhe: '+e.message;
    $('#error').style.display='block';
  }
}

/* eventos dos selects */
document.addEventListener('change', (e)=>{
  if(e.target && (e.target.id === 'postoSelect' || e.target.id === 'mesSelect')){
    atualizaChips();
    render();
  }
});

/* iniciar */
showView('home'); // inicia em home
loadData();
setInterval(loadData, 60000);
