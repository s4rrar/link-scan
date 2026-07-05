import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../viewmodels/barcode_viewmodel.dart';
import 'history_item_card.dart';

class HistoryTab extends StatelessWidget {
  final BarcodeViewModel viewModel;

  const HistoryTab({super.key, required this.viewModel});

  String formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = viewModel.isDarkMode;
        final primaryColor = polishPrimary;
        return BackdropFilter(
          filter: AppStyles.glassBlurFilter,
          child: AlertDialog(
            backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              side: BorderSide(
                color: (isDark ? Colors.white : primaryColor).withOpacity(0.2),
                width: 1.2,
              ),
            ),
            title: Text(
              'Delete Whole History?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: polishOnSurface),
            ),
            content: Text(
              'This action is permanent and will wipe all ${viewModel.scanHistory.length} locally stored barcode records.',
              style: TextStyle(color: polishOnSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel', style: TextStyle(color: polishOnSurfaceVariant)),
              ),
              TextButton(
                onPressed: () {
                  viewModel.clearHistory();
                  Navigator.of(ctx).pop();
                },
                child: Text('Delete All', style: TextStyle(color: polishError, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = viewModel.scanHistory;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCAN LOGS',
                    style: TextStyle(
                      color: polishPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${list.length} items stored',
                    style: TextStyle(
                      color: polishOnSurfaceVariant,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
              if (list.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmDialog(context),
                  icon: Icon(Icons.delete_sweep, color: polishError),
                  label: Text(
                    'Clear All',
                    style: TextStyle(color: polishError, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.content_paste_off_outlined,
                          color: polishOnSurfaceVariant.withOpacity(0.4),
                          size: 80.0,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          'History Log is Empty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: polishOnBackground,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Newly scanned codes will appear here automatically.',
                            style: TextStyle(
                              color: polishOnSurfaceVariant,
                              fontSize: 14.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10.0),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return HistoryItemCard(
                        item: item,
                        formattedTime: formatTimestamp(item.timestamp),
                        onCopy: () {
                          Clipboard.setData(ClipboardData(text: item.barcode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Barcode copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        onDelete: () {
                          if (item.id != null) {
                            viewModel.deleteScan(item.id!);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
