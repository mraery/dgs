import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class PromoCodeDialog extends ConsumerStatefulWidget {
  const PromoCodeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const PromoCodeDialog(),
    );
  }

  @override
  ConsumerState<PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends ConsumerState<PromoCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  PromoResult? _result;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyCode([String? predefinedCode]) {
    final codeToApply = predefinedCode ?? _controller.text;
    if (codeToApply.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = ref.read(userProfileProvider.notifier).applyPromoCode(codeToApply);

    setState(() {
      _isLoading = false;
      _result = result;
      if (predefinedCode != null) {
        _controller.text = predefinedCode;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: isDark ? const Color(0xFF1E1E26) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E26) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CB0F6).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFF1CB0F6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promosyon Kodu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF4B4B4B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'İndirim veya hediye kodunu gir',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Kod Giriş Alanı (Sadece yazı ile yazma kısmı)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262633) : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF383848) : const Color(0xFFE5E5E5),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Promosyon kodunu girin...',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF71717A) : Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(Icons.local_offer_rounded, color: Color(0xFF1CB0F6)),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _result = null);
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _applyCode(),
                ),
              ),

              // Sonuç Bildirimi
              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _result!.success
                        ? (_result!.isCheat
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFE8F5E9))
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _result!.success
                          ? (_result!.isCheat
                              ? const Color(0xFFFF9600)
                              : const Color(0xFF58CC02))
                          : const Color(0xFFFF4B4B),
                      width: 1.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _result!.success
                            ? (_result!.isCheat
                                ? Icons.whatshot_rounded
                                : Icons.check_circle_rounded)
                            : Icons.error_outline_rounded,
                        color: _result!.success
                            ? (_result!.isCheat
                                ? const Color(0xFFFF9600)
                                : const Color(0xFF58CC02))
                            : const Color(0xFFFF4B4B),
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _result!.message,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _result!.success
                                ? (_result!.isCheat
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF2E7D32))
                                : const Color(0xFFC62828),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Uygula Butonu
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                onPressed: _isLoading ? null : () => _applyCode(),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'KODU UYGULA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
