import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SurveillanceApp());
}

class SurveillanceApp extends StatefulWidget {
  const SurveillanceApp({super.key});

  @override
  State<SurveillanceApp> createState() => _SurveillanceAppState();
}

class _SurveillanceAppState extends State<SurveillanceApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigilancia IA',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: HomeScreen(
        onToggleTheme: () {
          setState(() {
            _themeMode =
                _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          });
        },
        isLight: _themeMode == ThemeMode.light,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onToggleTheme, required this.isLight});
  final VoidCallback onToggleTheme;
  final bool isLight;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final SurveillanceController controller = SurveillanceController();

  @override
  void initState() {
    super.initState();
    controller.startAutoSimulation(onNewEvent: _handleNewEvent);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleNewEvent(EventData event) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: event.priorityColor.withOpacity(0.9),
        content: Text(
          '${event.priorityLabel} • ${event.type} • ${event.location}',
          style: GoogleFonts.spaceGrotesk(
            textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(controller: controller),
      CamerasPage(controller: controller),
      EventsPage(controller: controller),
      SettingsPage(
        isLight: widget.isLight,
        onToggleTheme: widget.onToggleTheme,
        controller: controller,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam_outlined), label: 'Cámaras'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_outlined), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Config'),
        ],
      ),
    );
  }
}

// Controller and data
class SurveillanceController {
  final List<CameraData> cameras = [
    const CameraData('Lobby Principal', 'Edificio Central', true),
    const CameraData('Cajeros 24/7', 'Sucursal Norte', true),
    const CameraData('Bóveda', 'Subsuelo', false),
    const CameraData('Estacionamiento', 'Patio Oeste', true),
    const CameraData('Acceso Principal', 'Planta Baja', true),
  ];

  final List<EventData> eventsDB = [];
  final List<String> realThreats = [];
  final List<String> falsePositives = [];
  Timer? _autoTimer;
  final Random _rand = Random();

  void startAutoSimulation({required void Function(EventData) onNewEvent}) {
    void scheduleNext() {
      final delay = Duration(seconds: 10 + _rand.nextInt(11)); // 10-20s
      _autoTimer = Timer(delay, () {
        final event = _randomEvent();
        eventsDB.insert(0, event);
        onNewEvent(event);
        scheduleNext();
      });
    }

    scheduleNext();
  }

  void dispose() {
    _autoTimer?.cancel();
  }

  EventData addManualEvent() {
    final ev = _randomEvent();
    eventsDB.insert(0, ev);
    return ev;
  }

  EventData _randomEvent() {
    const pool = [
      ('Acceso no autorizado', 'Alta', '🚨'),
      ('Movimiento sospechoso', 'Media', '⚠️'),
      ('Persona desconocida', 'Baja', '👤'),
      ('Objeto abandonado', 'Alta', '🎒'),
      ('Entrega fuera de horario', 'Media', '📦'),
      ('Acceso forzado', 'Alta', '🛑'),
    ];
    final base = pool[_rand.nextInt(pool.length)];
    final cam = cameras[_rand.nextInt(cameras.length)];
    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return EventData(
      type: base.$1,
      priority: base.$2,
      icon: base.$3,
      camera: cam.name,
      location: cam.location,
      timestamp: timestamp,
    );
  }

  void markThreat(String type) => realThreats.add(type);
  void markFalsePositive(String type) => falsePositives.add(type);

  int get criticalCount => eventsDB.where((e) => e.priority == 'Alta').length;
}

class CameraData {
  final String name;
  final String location;
  final bool online;
  const CameraData(this.name, this.location, this.online);
}

class EventData {
  final String type;
  final String priority;
  final String icon;
  final String camera;
  final String location;
  final String timestamp;

  const EventData({
    required this.type,
    required this.priority,
    required this.icon,
    required this.camera,
    required this.location,
    required this.timestamp,
  });

  Color get priorityColor {
    switch (priority) {
      case 'Alta':
        return const Color(0xffe53935);
      case 'Media':
        return const Color(0xffffb74d);
      default:
        return const Color(0xff66bb6a);
    }
  }

  String get priorityLabel => priority;
}

// Pages
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.controller});
  final SurveillanceController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cooperativa Financiera', style: AppText.eyebrow(theme)),
                  Text('Sistema de Videovigilancia IA', style: AppText.title(theme)),
                ],
              ),
              const Icon(Icons.circle, color: Colors.greenAccent, size: 14),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricCard(label: 'Cámaras activas', value: controller.cameras.where((c) => c.online).length.toString(), chip: 'Operativas', color: AppColors.green),
              MetricCard(label: 'Eventos hoy', value: controller.eventsDB.length.toString(), chip: 'Monitoreando', color: AppColors.cyan),
              MetricCard(label: 'Alertas críticas', value: controller.criticalCount.toString(), chip: 'Prioridad', color: AppColors.red),
            ],
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Cámaras conectadas', subtitle: 'Feed en vivo', action: TextButton(onPressed: () {}, child: const Text('Ver todas'))),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.cameras.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.95),
            itemBuilder: (context, i) => CameraCard(camera: controller.cameras[i]),
          ),
        ],
      ),
    );
  }
}

class CamerasPage extends StatelessWidget {
  const CamerasPage({super.key, required this.controller});
  final SurveillanceController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.cameras.length,
      itemBuilder: (context, i) {
        final cam = controller.cameras[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Theme.of(context).cardColor,
          leading: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppGradients.preview,
            ),
          ),
          title: Text(cam.name, style: AppText.cardTitle(Theme.of(context))),
          subtitle: Text(cam.location, style: AppText.subtitle(Theme.of(context))),
          trailing: ElevatedButton(
            onPressed: () => _openLive(context, cam.name),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ver en vivo'),
          ),
        );
      },
    );
  }

  void _openLive(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LiveSheet(cameraName: name),
    );
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.controller});
  final SurveillanceController controller;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  void _simulate() {
    final ev = widget.controller.addManualEvent();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ev.priority} • ${ev.type} • ${ev.location}'),
        backgroundColor: ev.priorityColor,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.controller.eventsDB;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IA Watchlist', style: AppText.eyebrow(Theme.of(context))),
                  Text('Eventos de interés', style: AppText.title(Theme.of(context))),
                ],
              ),
              OutlinedButton(onPressed: _simulate, child: const Text('Simular alerta')),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('Sin eventos detectados aún.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = events[i];
                    return EventCard(
                      event: e,
                      onConfirm: () {
                        widget.controller.markThreat(e.type);
                        setState(() {});
                      },
                      onFalse: () {
                        widget.controller.markFalsePositive(e.type);
                        setState(() {});
                      },
                      onLive: () => _openLive(context, e.camera),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openLive(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LiveSheet(cameraName: name),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.isLight, required this.onToggleTheme, required this.controller});
  final bool isLight;
  final VoidCallback onToggleTheme;
  final SurveillanceController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Configuración', style: AppText.title(Theme.of(context))),
        const SizedBox(height: 12),
        SwitchListTile(
          value: controller.realThreats.length >= 0 ? !controller.realThreats.isEmpty || true : true,
          onChanged: (v) => onToggleTheme(),
          title: const Text('Tema Neón claro/oscuro'),
          subtitle: Text(isLight ? 'Neón claro' : 'Neón oscuro'),
          activeColor: AppColors.red,
        ),
        SwitchListTile(
          value: controller.realThreats.isEmpty, // dummy toggle
          onChanged: (_) {},
          title: const Text('Notificaciones críticas'),
          subtitle: const Text('Simulado en frontend'),
        ),
        SwitchListTile(
          value: controller.falsePositives.isEmpty, // dummy toggle
          onChanged: (_) {},
          title: const Text('Modo sigiloso'),
          subtitle: const Text('Silencia sonido de alerta'),
        ),
        ListTile(
          title: const Text('Refresco de feed'),
          subtitle: const Text('5s / 10s / 30s / Manual'),
          trailing: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Auto'),
          ),
        ),
      ],
    );
  }
}

// Widgets
class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.label, required this.value, required this.chip, required this.color});
  final String label;
  final String value;
  final String chip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.subtitle(Theme.of(context))),
          const SizedBox(height: 6),
          Text(value, style: AppText.metric(Theme.of(context))),
          const SizedBox(height: 6),
          Chip(
            label: Text(chip),
            backgroundColor: color.withOpacity(0.15),
            labelStyle: const TextStyle(color: Colors.white),
            side: BorderSide(color: color.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.subtitle, this.action});
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: AppText.eyebrow(Theme.of(context))),
            Text(title, style: AppText.section(Theme.of(context))),
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}

class CameraCard extends StatelessWidget {
  const CameraCard({super.key, required this.camera});
  final CameraData camera;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.preview,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(camera.name, style: AppText.cardTitle(Theme.of(context))),
                    Text(camera.location, style: AppText.subtitle(Theme.of(context))),
                  ],
                ),
                Chip(
                  label: Text(camera.online ? 'Activa' : 'Offline'),
                  backgroundColor: (camera.online ? AppColors.green : AppColors.red).withOpacity(0.15),
                  side: BorderSide(color: (camera.online ? AppColors.green : AppColors.red).withOpacity(0.6)),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onConfirm,
    required this.onFalse,
    required this.onLive,
  });
  final EventData event;
  final VoidCallback onConfirm;
  final VoidCallback onFalse;
  final VoidCallback onLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.priorityColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: event.priorityColor.withOpacity(0.2), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: event.priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(event.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.type, style: AppText.cardTitle(Theme.of(context))),
                    Text('${event.location} • ${event.timestamp}', style: AppText.subtitle(Theme.of(context))),
                    Text('Cámara: ${event.camera}', style: AppText.subtitle(Theme.of(context))),
                  ],
                ),
              ),
              Chip(
                label: Text(event.priority),
                backgroundColor: event.priorityColor.withOpacity(0.15),
                side: BorderSide(color: event.priorityColor.withOpacity(0.7)),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onConfirm,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.red),
                  ),
                  child: const Text('Confirmar amenaza'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onFalse,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.green),
                  ),
                  child: const Text('Falso positivo'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onLive,
                icon: const Icon(Icons.videocam_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LiveSheet extends StatelessWidget {
  const LiveSheet({super.key, required this.cameraName});
  final String cameraName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vista en vivo', style: AppText.section(Theme.of(context))),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppGradients.preview,
            ),
          ),
          const SizedBox(height: 12),
          Text(cameraName, style: AppText.cardTitle(Theme.of(context))),
          Text('Ubicación simulada', style: AppText.subtitle(Theme.of(context))),
        ],
      ),
    );
  }
}

// Theme and typography
class AppColors {
  static const red = Color(0xffe53935);
  static const green = Color(0xff3ad29f);
  static const cyan = Color(0xff2de2e6);
}

class AppTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xff050912),
    primaryColor: AppColors.red,
    textTheme: GoogleFonts.spaceGroteskTextTheme().apply(bodyColor: Colors.white),
    cardColor: const Color(0x23111b31),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xff0b1224),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xfff7f7fb),
    primaryColor: AppColors.red,
    textTheme: GoogleFonts.spaceGroteskTextTheme(),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.red,
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

class AppGradients {
  static const preview = LinearGradient(
    colors: [Color(0xff1e1f32), Color(0xff0b1224)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppText {
  static TextStyle title(ThemeData theme) => theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700);
  static TextStyle section(ThemeData theme) => theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700);
  static TextStyle cardTitle(ThemeData theme) => theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700);
  static TextStyle subtitle(ThemeData theme) => theme.textTheme.bodySmall!.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7));
  static TextStyle eyebrow(ThemeData theme) => theme.textTheme.labelSmall!.copyWith(
        letterSpacing: 1.8,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
      );
  static TextStyle metric(ThemeData theme) => theme.textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w800);
}
