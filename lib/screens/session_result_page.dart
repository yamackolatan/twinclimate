import 'package:flutter/material.dart';

import '../logic/gear_engine.dart';
import '../logic/weather_text.dart';
import '../models/comfort.dart';
import '../models/session.dart';
import '../models/weather.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';
import '../widgets/hour_cards.dart';
import '../widgets/kit_checklist.dart';

/// The answer screen: session-window forecast + what to wear and bring.
class SessionResultPage extends StatefulWidget {
  const SessionResultPage({
    super.key,
    required this.plan,
    required this.weather,
    this.store,
  });

  final SessionPlan plan;
  final WeatherService weather;

  /// When given, the kit uses the user's comfort profile and the session
  /// is remembered for the post-session feedback card (F4).
  final PrefsStore? store;

  @override
  State<SessionResultPage> createState() => _SessionResultPageState();
}

class _SessionResultPageState extends State<SessionResultPage> {
  late Future<SessionForecast> _forecast;

  @override
  void initState() {
    super.initState();
    _forecast = _load();
  }

  Future<SessionForecast> _load() async {
    final windowHours = widget.plan.windowHours;
    final all = await widget.weather.fetchHourly(
      place: widget.plan.place,
      firstDay: windowHours.first,
      lastDay: windowHours.last,
    );
    final byHour = {
      for (final hour in all)
        DateTime(
          hour.time.year,
          hour.time.month,
          hour.time.day,
          hour.time.hour,
        ): hour,
    };
    final matched = [
      for (final wanted in windowHours)
        if (byHour.containsKey(wanted)) byHour[wanted]!,
    ];
    if (matched.isEmpty) {
      throw WeatherServiceException(
        'No forecast is available yet for that date and time. '
        'Forecasts reach about 16 days ahead.',
      );
    }
    final forecast = SessionForecast(matched);
    await _remember(forecast);
    return forecast;
  }

  String get _sessionId => SessionRecord.idFor(
    widget.plan.sport,
    widget.plan.place.latitude,
    widget.plan.place.longitude,
    widget.plan.start,
  );

  Future<void> _remember(SessionForecast forecast) async {
    final store = widget.store;
    if (store == null) return;
    final plan = widget.plan;
    final kit = buildKitForPlan(plan, forecast, comfort: store.comfortProfile);
    await store.recordSession(
      SessionRecord(
        id: _sessionId,
        sport: plan.sport,
        placeName: plan.place.name,
        latitude: plan.place.latitude,
        longitude: plan.place.longitude,
        start: plan.start,
        end: plan.end,
        forecastFeelsC: forecast.meanApparentC,
        suggested: mainSuggestions(kit),
      ),
    );
  }

  Set<String> get _savedPacked {
    final store = widget.store;
    if (store == null) return const {};
    for (final r in store.sessionRecords) {
      if (r.id == _sessionId) return r.packed;
    }
    return const {};
  }

  void _onPacked(Set<String> packed, bool allPacked) {
    widget.store?.updateSession(
      _sessionId,
      (r) => r.copyWith(packed: packed, allPacked: allPacked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        title: Text(plan.place.name),
      ),
      body: FutureBuilder<SessionForecast>(
        future: _forecast,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorView(context, snapshot.error);
          }
          return _resultView(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _errorView(BuildContext context, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(
              error is WeatherServiceException
                  ? error.message
                  : 'Something went wrong while loading the forecast.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => setState(() => _forecast = _load()),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultView(BuildContext context, SessionForecast forecast) {
    final plan = widget.plan;
    final kit = buildKitForPlan(
      plan,
      forecast,
      comfort: widget.store?.comfortProfile,
    );
    final scheme = Theme.of(context).colorScheme;
    final start = forecast.atStart;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // What was asked for.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(context, Icons.flag, plan.sport.label),
                    _chip(context, Icons.calendar_today, formatDay(plan.start)),
                    _chip(context, Icons.schedule, plan.windowLabel),
                    _chip(context, Icons.route, plan.distanceLabel),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary: feels-like at start + sky + humidity + wind.
                Card(
                  elevation: 0,
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          weatherIcon(start.weatherCode, isDay: start.isDay),
                          size: 44,
                          color: scheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feels like ${start.apparentC.round()}° at the start',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${weatherDescription(start.weatherCode)} · '
                                '${start.humidityPercent.round()}% humidity · '
                                '${windPhrase(forecast.maxWindKmh, forecast.maxGustKmh)}',
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                              if (forecast.rainLikely) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Rain chance up to ${forecast.maxPrecipProbabilityPercent.round()}% during your session.',
                                  style: TextStyle(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Hour by hour',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                HourCards(hours: forecast.hours),
                const SizedBox(height: 20),

                KitChecklist(
                  items: kit,
                  initialPacked: _savedPacked,
                  onPackedChanged: _onPacked,
                ),
                const SizedBox(height: 24),

                Text(
                  'Forecast by Open-Meteo for the exact coordinates of '
                  '${plan.place.name} '
                  '(${plan.place.latitude.toStringAsFixed(3)}, '
                  '${plan.place.longitude.toStringAsFixed(3)}), local time.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
