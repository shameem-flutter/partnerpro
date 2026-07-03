import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Shown when the API returns a permission-denied error,
/// e.g. {"error": "You do not have permission to view ..."}
class PermissionDeniedWidget extends StatelessWidget {
  const PermissionDeniedWidget({
    super.key,
    required this.message,
    this.onBack,
  });

  final String message;

  /// Optional callback for a back button. Pass null to hide the button.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon with red circle background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 50,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // Server message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Hint text
            Text(
              'Your account does not have the required permissions '
              'to access this section. Please contact your administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),

            if (onBack != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
