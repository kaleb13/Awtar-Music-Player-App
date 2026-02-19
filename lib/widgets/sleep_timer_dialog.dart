import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sleep_timer_provider.dart';
import '../theme/app_theme.dart';

class SleepTimerDialog extends ConsumerStatefulWidget {
  const SleepTimerDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => const SleepTimerDialog(),
    );
  }

  @override
  ConsumerState<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends ConsumerState<SleepTimerDialog> {
  int _selectedMinutes = 30;
  bool _finishLastTrack = false;
  final TextEditingController _customController = TextEditingController();

  final List<int> _options = [5, 10, 15, 30, 45, 60, 90, 120];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _showCustomDurationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePopover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text("Custom Duration", style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: "Minutes",
                labelStyle: const TextStyle(color: Colors.white54),
                suffixText: "min",
                suffixStyle: const TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accentBlue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(_customController.text);
              if (val != null && val > 0) {
                setState(() {
                  _selectedMinutes = val;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Apply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(sleepTimerProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfacePopover,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          Icon(Icons.timer_outlined, color: AppColors.accentBlue, size: 28),
          const SizedBox(width: 12),
          Text(
            "Sleep Timer",
            style: AppTextStyles.titleMedium.copyWith(letterSpacing: 0.5),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timerState.isActive) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Remaining Time",
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timerState.remainingTimeString,
                    style: AppTextStyles.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentBlue,
                      letterSpacing: 2,
                    ),
                  ),
                  if (timerState.finishLastTrack)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Finishing last track...",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentBlue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Set Duration",
                style: AppTextStyles.caption.copyWith(color: Colors.white38),
              ),
              GestureDetector(
                onTap: _showCustomDurationPicker,
                child: Text(
                  "Set custom duration",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_options.contains(_selectedMinutes))
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Custom: $_selectedMinutes min",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((mins) {
              final isSelected = _selectedMinutes == mins;
              return GestureDetector(
                onTap: () => setState(() => _selectedMinutes = mins),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentBlue
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    "$mins min",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _finishLastTrack = !_finishLastTrack),
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _finishLastTrack,
                      onChanged: (val) =>
                          setState(() => _finishLastTrack = val ?? false),
                      activeColor: AppColors.accentBlue,
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Finish last track",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Wait for current song to end",
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white38),
          ),
        ),
        if (timerState.isActive)
          TextButton(
            onPressed: () {
              ref.read(sleepTimerProvider.notifier).cancelTimer();
              Navigator.pop(context);
            },
            child: Text(
              "Turn Off",
              style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            ref
                .read(sleepTimerProvider.notifier)
                .setTimer(
                  Duration(minutes: _selectedMinutes),
                  _finishLastTrack,
                );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            timerState.isActive ? "Restart" : "Set Timer",
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

