import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/best_time.dart';
import '../logic/gear_engine.dart';
import '../logic/share_text.dart';
import '../logic/shop_logic.dart';
import '../logic/typical_weather.dart';
import '../logic/weather_text.dart';
import '../models/comfort.dart';
import '../models/gear.dart';
import '../models/session.dart';
import '../models/weather.dart';
import '../services/device_services.dart';
import '../services/prefs_store.dart';
import '../services/typical_weather_service.dart';
import '../services/weather_service.dart';
import '../theme.dart';
import '../widgets/hour_cards.dart';
import '../widgets/kit_checklist.dart';
import '../widgets/product_sheet.dart';

/// The answer screen: session-window forecast + what to wear and bring.
class SessionResultPage extends StatefulWidget {
  const SessionResultPage({
    super.key,
    required this.plan,
    required this.weather,
    this.store,
    this.onPlanChanged,
  });

  final SessionPlan plan;
  final WeatherService weather;

  /// Told when the user moves the session from this screen ("1 h later"),
  /// so the form behind it shows the same time.
  final void Function(SessionPlan plan)? onPlanChanged;

  /// When given, the kit uses the user's comfort profile and the session
  /// is remembered for the post-session feedback card (F4).
  final PrefsStore? store;

  @override
  State<SessionResultPage> createState() => _SessionResultPageState();
}

class _SessionResultPageState extends State<SessionResultPage> {
  late Future<SessionForecast> _forecast;

  /// Set when the date is past the 16-day forecast and typical weather
  /// from the last 10 years is shown instead.
  TypicalSession? _typical;

  /// The whole day's forecast, for the "better time" hint.
  List<HourWeather> _dayHours = const [];

  bool get _isTypical => beyondForecast(widget.plan.start, DateTime.now());

  @override
  void initState() {
    super.initState();
    _forecast = _load();
  }

  Future<SessionForecast> _load() async {
    if (_isTypical) {
      final typical = await TypicalWeatherService(
        widget.weather,
      ).forSession(widget.plan.place, widget.plan.windowHours);
      _typical = typical;
      await _remember(typical.forecast);
      return typical.forecast;
    }
    final windowHours = widget.plan.windowHours;
    final all = await widget.weather.fetchHourly(
      place: widget.plan.place,
      firstDay: windowHours.first,
      lastDay: windowHours.last,
    );
    _dayHours = all;
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
    final store = widget.store;
    store?.updateSession(
      _sessionId,
      (r) => r.copyWith(packed: packed, allPacked: allPacked),
    );
    // Packing an item means owning it (its shop link then offers other
    // models).
    final types = [for (final name in packed) ...?itemProductTypes[name]];
    if (store != null && types.any((t) => !store.ownedTypes.contains(t))) {
      store.markOwned(types).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Shop suggestion types already counted as "shown" on this screen.
  final Set<String> _countedShown = {};

  Set<GearItem> _shopItems(List<GearItem> kit) {
    final store = widget.store;
    if (store == null || !store.shopSuggestionsOn) return const {};
    final items = itemsToOffer(kit);
    for (final item in items) {
      for (final type in itemProductTypes[item.name]!) {
        if (_countedShown.add(type)) store.countShop('shown', type);
      }
    }
    return items;
  }

  Future<void> _openShop(GearItem item) async {
    final owned = await ProductSheet.show(
      context,
      title: item.name,
      why: item.reason,
      products: productsForItem(item),
      types: itemProductTypes[item.name] ?? const [],
      store: widget.store,
      owned: ownsItem(item, widget.store?.ownedTypes ?? const {}),
    );
    if (owned && mounted) setState(() {});
  }

  /// What's on screen, for the Share button.
  SessionForecast? _shown;

  Future<void> _share() async {
    final forecast = _shown;
    if (forecast == null) return;
    final plan = widget.plan;
    final text = sessionShareText(
      plan,
      forecast,
      buildKitForPlan(plan, forecast, comfort: widget.store?.comfortProfile),
      typical: _typical != null,
    );
    if (await shareText(text)) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kit list copied — paste it anywhere.')),
    );
  }

  /// Re-runs the same session [hours] earlier or later.
  void _shift(int hours) =>
      _moveTo(widget.plan.start.add(Duration(hours: hours)));

  void _moveTo(DateTime start) {
    final moved = widget.plan.movedTo(start);
    widget.onPlanChanged?.call(moved);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, _, _) => SessionResultPage(
          plan: moved,
          weather: widget.weather,
          store: widget.store,
          onPlanChanged: widget.onPlanChanged,
        ),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.place.name),
        actions: [
          IconButton(
            tooltip: 'Change session',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          IconButton(
            tooltip: 'Share kit list',
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
        ],
      ),
      body: FutureBuilder<SessionForecast>(
        future: _forecast,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isTypical
                          ? 'Looking at 10 years of weather for '
                                '${plan.place.name}…\nThis can take a little '
                                'while.'
                          : 'Getting the forecast for ${plan.place.name}…',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
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
            // A daily or hourly limit won't lift in seconds: no button.
            if (error is! WeatherServiceException ||
                error.retryable ||
                error.perMinuteLimit) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => _forecast = _load()),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
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
    final shopItems = _shopItems(kit);
    _shown = forecast;
    final now = DateTime.now();
    final canGoEarlier = plan.start
        .subtract(const Duration(hours: 1))
        .isAfter(now.subtract(const Duration(minutes: 30)));

    final weatherColumn = <Widget>[
      _hero(context, forecast),
      if (_typical != null) ...[
        const SizedBox(height: 12),
        _typicalBanner(context, _typical!),
      ],
      const SizedBox(height: 20),
      Text('Hour by hour', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      HourCards(hours: forecast.hours),
      const SizedBox(height: 8),
      if (_typical == null) _betterTimeHint(context, forecast),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canGoEarlier ? () => _shift(-1) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('1 h earlier'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shift(1),
              icon: const Icon(Icons.chevron_right),
              label: const Text('1 h later'),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    ];
    final kitColumn = <Widget>[
      KitChecklist(
        items: kit,
        initialPacked: _savedPacked,
        onPackedChanged: _onPacked,
        shopItems: shopItems,
        ownedShopItems: {
          for (final item in shopItems)
            if (ownsItem(item, widget.store!.ownedTypes)) item,
        },
        onShop: _openShop,
      ),
      if (shopItems.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          shopDisclosure,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    ];
    final footer = Text(
      '${_typical == null ? 'Forecast' : 'Typical weather from recorded history (ERA5)'} '
      'by Open-Meteo for the exact coordinates of '
      '${plan.place.name} '
      '(${plan.place.latitude.toStringAsFixed(3)}, '
      '${plan.place.longitude.toStringAsFixed(3)}), local time.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      textAlign: TextAlign.center,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide screens: weather on the left, kit on the right.
        final wide = constraints.maxWidth >= 1000;
        final body = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: weatherColumn,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: kitColumn,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...weatherColumn,
                  const SizedBox(height: 24),
                  ...kitColumn,
                ],
              );
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1200 : 640),
              child: Padding(
                padding: pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    body,
                    const SizedBox(height: 24),
                    footer,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The headline card: what was asked, how it will feel, one verdict.
  Widget _hero(BuildContext context, SessionForecast forecast) {
    final plan = widget.plan;
    final start = forecast.atStart;
    final text = Theme.of(context).textTheme;
    const onHero = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.95);
    final colors = feelGradient(
      forecast.kitFeelsC,
      Theme.of(context).brightness,
    );
    final details = <String>[
      '${weatherDescription(start.weatherCode)} · '
          '${start.humidityPercent.round()}% humidity · '
          '${windPhraseWithDirection(forecast.maxWindKmh, forecast.maxGustKmh, forecast.windFromDeg)}',
      if (forecast.rainLikely)
        'Rain chance up to ${forecast.maxPrecipProbabilityPercent.round()}% '
            'during your session.',
      if (forecast.sunrise != null && forecast.sunset != null)
        'Sunrise ${formatTime(forecast.sunrise!)} · '
            'sunset ${formatTime(forecast.sunset!)}',
      if (plan.sport == Sport.bike &&
          forecast.windy &&
          forecast.windFromDeg != null)
        'Tip: ride out into the wind (head '
            '${compassPoint(forecast.windFromDeg!)}) so it pushes you home '
            'when you\'re tired.',
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${plan.sport.label} · ${plan.distanceLabel}'
            '${plan.pool ? ' · pool' : ''} · ${formatDay(plan.start)} · '
            '${plan.windowLabel}',
            style: text.labelLarge?.copyWith(color: soft),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                weatherIcon(start.weatherCode, isDay: start.isDay),
                size: 56,
                color: onHero,
              ),
              const SizedBox(width: 16),
              Text(
                '${start.apparentC.round()}°',
                style: text.displayMedium?.copyWith(
                  color: onHero,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _typical == null
                      ? 'feels like\nat the start'
                      : 'typically feels\nlike at the start',
                  style: text.titleSmall?.copyWith(color: soft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sessionVerdict(
              feelsC: forecast.kitFeelsC,
              wet: forecast.rainLikely,
              windy: forecast.windy,
            ),
            style: text.titleLarge?.copyWith(color: onHero),
          ),
          const SizedBox(height: 6),
          for (final line in details)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(line, style: text.bodyMedium?.copyWith(color: soft)),
            ),
        ],
      ),
    );
  }

  Widget _betterTimeHint(BuildContext context, SessionForecast forecast) {
    final better = betterTime(
      plan: widget.plan,
      day: _dayHours,
      now: DateTime.now(),
    );
    if (better == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: scheme.secondaryContainer,
        child: ListTile(
          leading: Icon(Icons.schedule, color: scheme.onSecondaryContainer),
          title: Text(
            'Better at ${formatTime(better.start)}',
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            better.why,
            style: TextStyle(color: scheme.onSecondaryContainer),
          ),
          trailing: Icon(
            Icons.arrow_forward,
            color: scheme.onSecondaryContainer,
          ),
          onTap: () => _moveTo(better.start),
        ),
      ),
    );
  }

  Widget _typicalBanner(BuildContext context, TypicalSession t) {
    final scheme = Theme.of(context).colorScheme;
    final range = t.feelsSpread;
    final from = forecastAvailableFrom(widget.plan.start);
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.history, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Typical weather, not a forecast. This date is more than 16 '
                'days away, so we show the average at this spot for '
                '${formatDayMonth(widget.plan.start)} ±5 days over '
                '${t.firstYear}–${t.lastYear}: usually feels like '
                '${range.low.round()}–${range.high.round()}° during your '
                'session. The real forecast is available from '
                '${formatDay(from)}.',
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
