import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One bucket of the trend line: everything spent on [day].
class SpendingTrendPoint {
  const SpendingTrendPoint({required this.day, required this.amount});

  final DateTime day;
  final double amount;
}

/// Spending over a period, with the change against the previous period.
///
/// Takes its numbers as arguments rather than reading a bloc, so the same widget
/// serves the dashboard, the reports screens and golden tests.
class SpendingTrendsChart extends StatelessWidget {
  const SpendingTrendsChart({
    super.key,
    required this.points,
    this.previousPeriodTotal,
    this.currencySymbol = r'$',
    this.comparisonLabel = 'vs. previous period',
  });

  /// Chronological buckets to plot. An empty list renders the empty state.
  final List<SpendingTrendPoint> points;

  /// Total for the preceding period. When null, or zero, no delta is shown --
  /// a percentage change from zero is not a meaningful number to display.
  final double? previousPeriodTotal;

  final String currencySymbol;
  final String comparisonLabel;

  double get _total => points.fold(0, (sum, p) => sum + p.amount);

  /// Signed percentage change against [previousPeriodTotal], or null when there
  /// is no usable baseline.
  double? get _deltaPercent {
    final previous = previousPeriodTotal;
    if (previous == null || previous == 0) return null;
    return (_total - previous) / previous * 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.sm,
      ),
      padding: context.space.allXxl,
      decoration: BridgeDecoration(
        color: theme.colorScheme.surface,
        borderRadius: context.kit.radii.extraLarge,
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENDING TRENDS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (points.isEmpty)
            _EmptyState(theme: theme)
          else ...[
            _header(context, theme, primaryColor),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _TrendPainter(
                    color: primaryColor,
                    amounts: [for (final p in points) p.amount],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _axisLabels(theme),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, ThemeData theme, Color primaryColor) {
    final delta = _deltaPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(
                symbol: currencySymbol,
                decimalDigits: 2,
              ).format(_total),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (delta != null) ...[
              const SizedBox(width: 8),
              _deltaBadge(context, theme, primaryColor, delta),
            ],
          ],
        ),
        if (delta != null)
          Text(
            comparisonLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  /// Spending less than last period is the good direction, so a fall is shown in
  /// the primary colour and a rise in the error colour.
  Widget _deltaBadge(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
    double delta,
  ) {
    final isIncrease = delta > 0;
    final color = isIncrease ? theme.colorScheme.error : primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BridgeDecoration(
        color: color.withOpacity(0.1),
        borderRadius: context.kit.radii.xsmall,
      ),
      child: Row(
        children: [
          Icon(
            isIncrease ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${delta.abs().toStringAsFixed(0)}%',
            style: BridgeTextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// One label per point, thinned out so they cannot overlap on long ranges.
  Widget _axisLabels(ThemeData theme) {
    final stride = (points.length / 7).ceil();
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < points.length; i += stride)
          Text(DateFormat.E().format(points[i].day), style: style),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Center(
        child: Text(
          'No spending in this period',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Plots [amounts] as a smoothed line with a gradient fill beneath it.
class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.color, required this.amounts});

  final Color color;
  final List<double> amounts;

  @override
  void paint(Canvas canvas, Size size) {
    if (amounts.isEmpty) return;

    final points = _resolvePoints(size);

    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _smoothPath(points);
    canvas.drawPath(path, line);

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, fill);
  }

  /// Maps amounts onto the canvas, scaled to the largest value so the line
  /// always uses the full height.
  ///
  /// The baseline is zero rather than the smallest value: starting at the
  /// minimum would make a flat week look like a dramatic climb.
  List<Offset> _resolvePoints(Size size) {
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    final span = maxAmount <= 0 ? 1.0 : maxAmount;
    final stepX = amounts.length == 1 ? 0.0 : size.width / (amounts.length - 1);

    return [
      for (var i = 0; i < amounts.length; i++)
        Offset(
          amounts.length == 1 ? size.width / 2 : stepX * i,
          size.height - (amounts[i] / span) * size.height,
        ),
    ];
  }

  /// Each segment is a cubic whose control points are pulled to the segment's
  /// horizontal midpoint, which smooths the join while keeping the curve passing
  /// exactly through every data point.
  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      path.lineTo(points.first.dx, points.first.dy);
      return path;
    }

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.color != color || !_sameAmounts(oldDelegate.amounts);

  bool _sameAmounts(List<double> other) {
    if (other.length != amounts.length) return false;
    for (var i = 0; i < amounts.length; i++) {
      if (other[i] != amounts[i]) return false;
    }
    return true;
  }
}
