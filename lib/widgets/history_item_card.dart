import 'package:flutter/material.dart';
import '../models/scan_item.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';

class HistoryItemCard extends StatelessWidget {
  final ScanItem item;
  final String formattedTime;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.formattedTime,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = item.sentSuccessfully ? const Color(0xFF2E7D32) : polishError;
    final statusText = item.sentSuccessfully ? 'Sent to PC' : 'Failed';
    final isDark = AppThemeState.isDark;

    return GlassContainer(
      isDark: isDark,
      primaryColor: polishPrimary,
      borderRadius: AppStyles.radiusMedium,
      padding: const EdgeInsets.all(14.0),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.0),
            ),
            alignment: Alignment.center,
            child: Icon(
              item.format.toUpperCase().contains('QR') ? Icons.qr_code_2 : Icons.inventory,
              color: polishPrimary,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.format,
                      style: TextStyle(
                        color: polishPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  item.barcode,
                  style: TextStyle(
                    color: polishOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Icon(Icons.access_time, color: polishOnSurfaceVariant, size: 12.0),
                    const SizedBox(width: 4.0),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        color: polishOnSurfaceVariant,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.content_copy, color: polishPrimary),
                onPressed: onCopy,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: polishError),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
