import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/question_service.dart';
import 'package:share_plus/share_plus.dart';

class TransferChainScreen extends StatefulWidget {
  const TransferChainScreen({super.key});

  @override
  State<TransferChainScreen> createState() => _TransferChainScreenState();
}

class _TransferChainScreenState extends State<TransferChainScreen> {
  late List<Map<String, dynamic>> _chains;
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  bool _answered = false;
  bool _isCorrect = false;
  int _selectedOption = -1;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _chains = QuestionService.getTransferChains();
    _chains.shuffle();
    _buildOptions();
  }

  void _buildOptions() {
    final correct = _chains[_currentIndex]['name'] as String;
    final allNames = _chains.map((c) => c['name'] as String).where((n) => n != correct).toList();
    allNames.shuffle();
    _options = [correct, ...allNames.take(3)];
    _options.shuffle();
  }

  void _selectOption(int i) {
    if (_answered) return;
    final correct = _chains[_currentIndex]['name'] as String;
    final isCorrect = _options[i] == correct;
    setState(() { _selectedOption = i; _answered = true; _isCorrect = isCorrect; if (isCorrect) { _score += 100; _correctCount++; } });
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (_currentIndex < _chains.length - 1) {
      setState(() { _currentIndex++; _answered = false; _isCorrect = false; _selectedOption = -1; });
      _buildOptions();
    } else { _showResults(); }
  }

  void _showResults() {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(children: [
        const Icon(Icons.flight_takeoff, color: AppColors.primaryOrange, size: 56),
        const SizedBox(height: 12),
        const Text('Oyun Bitti!', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$_score RP', style: const TextStyle(color: AppColors.primaryOrange, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$_correctCount / ${_chains.length} doğru', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton.icon(onPressed: () async {
          await SharePlus.instance.share(ShareParams(text: 'Falso ile Transfer Yolculuğu oyununda $_score RP kazandım!'));
        }, icon: const Icon(Icons.share, color: AppColors.primaryOrange), label: const Text('Paylaş', style: TextStyle(color: AppColors.primaryOrange))),
        const SizedBox(height: 8),
        GradientButton(text: 'Ana Sayfaya Dön', onTap: () { Navigator.pop(context); Navigator.pop(context); }, gradient: AppColors.greenGradient),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final chainData = _chains[_currentIndex];
    final chain = chainData['chain'] as List;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top bar
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(icon: const Icon(Icons.close, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
                Text('${_currentIndex + 1}/${_chains.length}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: AppDecorations.glassBox(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, color: AppColors.primaryOrange, size: 16),
                    const SizedBox(width: 4),
                    Text('$_score', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              const Text('Bu transfer yolculuğu kimin?', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Transfer chain with logos + years
              Expanded(
                child: ListView.builder(
                  itemCount: chain.length,
                  itemBuilder: (context, index) {
                    final entry = chain[index] as Map<String, dynamic>;
                    final teamName = entry['team'] as String;
                    final logo = entry['logo'] as String? ?? '';
                    final years = entry['years'] as String? ?? '';
                    final isLast = index == chain.length - 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline
                          Column(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withAlpha(30),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                              ),
                              child: Center(child: Text('${index + 1}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11))),
                            ),
                            if (!isLast) Container(width: 2, height: 30, color: AppColors.primaryBlue.withAlpha(40)),
                          ]),
                          const SizedBox(width: 10),
                          // Card
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: AppDecorations.cardBox(),
                              child: Row(children: [
                                if (logo.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(logo, width: 30, height: 30, errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: AppColors.textSecondary, size: 30)),
                                  )
                                else
                                  const Icon(Icons.shield, color: AppColors.textSecondary, size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(teamName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    if (years.isNotEmpty)
                                      Text(years, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ]),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // MCQ options or result
              if (_answered) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isCorrect ? AppColors.correct.withAlpha(25) : AppColors.wrong.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isCorrect ? AppColors.correct : AppColors.wrong, width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: _isCorrect ? AppColors.correct : AppColors.wrong, size: 22),
                    const SizedBox(width: 8),
                    Text(chainData['name'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ] else ...[
                const SizedBox(height: 6),
                ...List.generate(4, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AnswerButton(
                      text: _options[i],
                      label: ['A', 'B', 'C', 'D'][i],
                      onTap: () => _selectOption(i),
                      isSelected: _selectedOption == i,
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
