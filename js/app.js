const UI = {
  toast: document.getElementById('alert-toast'),
  sound: document.getElementById('alert-sound'),
  triggers: document.querySelectorAll('.trigger-alert'),
  liveButtons: document.querySelectorAll('.live-link'),
  liveTitle: document.getElementById('live-title'),
  liveLocation: document.getElementById('live-location'),
  liveCamera: document.getElementById('live-camera'),
  eventsCount: document.getElementById('events-count'),
  criticalCount: document.getElementById('critical-count'),
  eventList: document.querySelector('.event-list'),
  eventsEmpty: document.getElementById('events-empty'),
  modal: document.getElementById('event-overlay'),
  modalClose: document.getElementById('modal-close'),
  modalType: document.getElementById('modal-type'),
  modalMeta: document.getElementById('modal-meta'),
  modalPriority: document.getElementById('modal-priority'),
  modalCamera: document.getElementById('modal-camera'),
  modalLive: document.getElementById('modal-live'),
  btnThreat: document.getElementById('btn-threat'),
  btnFalse: document.getElementById('btn-false'),
  btnLive: document.getElementById('btn-live'),
  countThreats: document.getElementById('count-threats'),
  countFalse: document.getElementById('count-false'),
  toggleNotif: document.getElementById('toggle-notif'),
  toggleSilent: document.getElementById('toggle-silent'),
  pillRefresh: document.getElementById('pill-refresh'),
  refreshLabel: document.getElementById('refresh-label'),
  pillTheme: document.getElementById('pill-theme'),
  themeLabel: document.getElementById('theme-label'),
};

const state = {
  notifications: true,
  silent: false,
  refreshSteps: ['Cada 5 segundos', 'Cada 10 segundos', 'Cada 30 segundos', 'Manual'],
  refreshIndex: 0,
  eventsDB: [],
  realThreats: [],
  falsePositives: [],
};

const EVENT_POOL = [
  { type: 'Acceso no autorizado', priority: 'Alta', icon: '🚨' },
  { type: 'Movimiento sospechoso', priority: 'Media', icon: '⚠️' },
  { type: 'Persona desconocida', priority: 'Baja', icon: '👤' },
  { type: 'Objeto abandonado', priority: 'Alta', icon: '🎒' },
  { type: 'Entrega fuera de horario', priority: 'Media', icon: '📦' },
  { type: 'Acceso forzado', priority: 'Alta', icon: '🛑' },
];

const CAMERAS = [
  { name: 'Lobby Principal', location: 'Edificio Central' },
  { name: 'Bóveda', location: 'Subsuelo' },
  { name: 'Cajeros 24/7', location: 'Sucursal Norte' },
  { name: 'Estacionamiento', location: 'Patio Oeste' },
  { name: 'Acceso Principal', location: 'Planta Baja' },
  { name: 'Puerta Sur', location: 'Perímetro' },
];

const randomBetween = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

const formatTimestamp = () => {
  const now = new Date();
  return now.toLocaleDateString('es-EC', { day: '2-digit', month: 'short', year: 'numeric' }) +
    ' • ' +
    now.toLocaleTimeString('es-EC', { hour: '2-digit', minute: '2-digit', hour12: false });
};

const priorityClass = (priority) => {
  if (priority === 'Alta') return 'high';
  if (priority === 'Media') return 'medium';
  return 'low';
};

const priorityPillClass = (priority) => {
  if (priority === 'Alta') return 'pill-red';
  if (priority === 'Media') return 'pill-amber';
  return 'pill-green';
};

const showToast = (title, body) => {
  UI.toast.classList.add('show');
  UI.toast.querySelector('.toast-title').textContent = title;
  UI.toast.querySelector('.toast-body').textContent = body;
  if (state.notifications && !state.silent) {
    UI.sound.currentTime = 0;
    UI.sound.play().catch(() => {});
  }
  setTimeout(() => UI.toast.classList.remove('show'), 3200);
};

const updateMetrics = () => {
  UI.eventsCount.textContent = state.eventsDB.length;
  const critical = state.eventsDB.filter((e) => e.priority === 'Alta').length;
  UI.criticalCount.textContent = critical;
  UI.countThreats.textContent = `Amenazas: ${state.realThreats.length}`;
  UI.countFalse.textContent = `Falsos positivos: ${state.falsePositives.length}`;
};

const bindEventCard = (card) => {
  card.addEventListener('click', () => openModal(card));
};

const appendEvent = (event) => {
  const card = document.createElement('article');
  card.className = `event-card ${priorityClass(event.priority)} selectable`;
  card.dataset.type = event.type;
  card.dataset.meta = `${event.location} • ${event.timestamp}`;
  card.dataset.camera = event.camera;
  card.dataset.priority = event.priority;

  card.innerHTML = `
    <div class="icon-circle">${event.icon}</div>
    <div class="event-body">
      <p class="event-type">${event.type}</p>
      <p class="event-meta">${event.location} • ${event.timestamp}</p>
      <p class="event-camera">Cámara: ${event.camera}</p>
    </div>
    <span class="pill ${priorityPillClass(event.priority)}">${event.priority}</span>
  `;

  bindEventCard(card);
  if (UI.eventsEmpty) {
    UI.eventsEmpty.remove();
    UI.eventsEmpty = null;
  }
  UI.eventList.prepend(card);
};

const recordEvent = (event) => {
  state.eventsDB.push(event);
  appendEvent(event);
  updateMetrics();
  showToast(`Nuevo evento (${event.priority})`, `${event.type} • ${event.camera}`);
};

const randomEvent = () => {
  const base = EVENT_POOL[randomBetween(0, EVENT_POOL.length - 1)];
  const cam = CAMERAS[randomBetween(0, CAMERAS.length - 1)];
  return {
    ...base,
    camera: cam.name,
    location: cam.location,
    timestamp: formatTimestamp(),
  };
};

const scheduleAutoEvent = () => {
  const delay = randomBetween(10000, 20000);
  setTimeout(() => {
    recordEvent(randomEvent());
    scheduleAutoEvent();
  }, delay);
};

const openModal = (card) => {
  UI.modalType.textContent = card.dataset.type;
  UI.modalMeta.textContent = card.dataset.meta;
  UI.modalCamera.textContent = `Cámara: ${card.dataset.camera}`;
  UI.modalPriority.textContent = card.dataset.priority;
  UI.modal.classList.add('show');
  UI.modalLive.classList.remove('show');
  UI.btnLive.textContent = 'Ver cámara';
};

const closeModal = () => UI.modal.classList.remove('show');

const markThreat = () => {
  state.realThreats.push(UI.modalType.textContent);
  updateMetrics();
  showToast('Amenaza registrada', UI.modalType.textContent);
  closeModal();
};

const markFalsePositive = () => {
  state.falsePositives.push(UI.modalType.textContent);
  updateMetrics();
  showToast('Falso positivo registrado', UI.modalType.textContent);
  closeModal();
};

const toggleLive = () => {
  const visible = UI.modalLive.classList.toggle('show');
  UI.btnLive.textContent = visible ? 'Ocultar cámara' : 'Ver cámara';
};

const openLive = (name) => {
  UI.liveTitle.textContent = name;
  UI.liveLocation.textContent = `Ubicación: ${name}`;
  UI.liveCamera.textContent = `#${name.replace(/\s+/g, '-').toUpperCase()}`;
  window.location.hash = 'live-view';
};

const toggleSwitch = (el, key, label) => {
  const isOn = el.classList.toggle('on');
  el.classList.toggle('off', !isOn);
  state[key] = isOn;
  showToast(label, isOn ? 'Activadas' : 'Desactivadas');
};

const cycleRefresh = () => {
  state.refreshIndex = (state.refreshIndex + 1) % state.refreshSteps.length;
  UI.refreshLabel.textContent = state.refreshSteps[state.refreshIndex];
  UI.pillRefresh.textContent = state.refreshIndex === state.refreshSteps.length - 1 ? 'Manual' : 'Auto';
  showToast('Frecuencia de refresco', UI.refreshLabel.textContent);
};

const toggleTheme = () => {
  const light = document.body.classList.toggle('theme-light');
  UI.themeLabel.textContent = light ? 'Neón claro' : 'Neón oscuro';
  UI.pillTheme.textContent = light ? 'Claro' : 'Activo';
  UI.pillTheme.classList.toggle('pill-cyan', light);
  UI.pillTheme.classList.toggle('pill-green', !light);
  showToast('Tema aplicado', UI.themeLabel.textContent);
};

const bindBaseListeners = () => {
  UI.modalClose.addEventListener('click', closeModal);
  UI.modal.addEventListener('click', (e) => { if (e.target === UI.modal) closeModal(); });
  UI.btnThreat.addEventListener('click', markThreat);
  UI.btnFalse.addEventListener('click', markFalsePositive);
  UI.btnLive.addEventListener('click', toggleLive);
  UI.liveButtons.forEach((btn) => btn.addEventListener('click', () => openLive(btn.dataset.live)));
  UI.toggleNotif.addEventListener('click', () => toggleSwitch(UI.toggleNotif, 'notifications', 'Notificaciones críticas'));
  UI.toggleSilent.addEventListener('click', () => toggleSwitch(UI.toggleSilent, 'silent', 'Modo sigiloso'));
  UI.pillRefresh.addEventListener('click', cycleRefresh);
  UI.pillTheme.addEventListener('click', toggleTheme);
  UI.triggers.forEach((btn) => btn.addEventListener('click', () => recordEvent(randomEvent())));
};

const init = () => {
  bindBaseListeners();
  scheduleAutoEvent();
};

init();
