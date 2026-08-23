import 'package:flutter/material.dart';

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  static const _duas = <({String title, String arabic, String meaning})>[
    (
      title: 'Yemek Duası',
      arabic: 'Bismillâhirrahmânirrahîm',
      meaning: 'Rahmân ve Rahîm olan Allah’ın adıyla.',
    ),
    (
      title: 'Rabbenâ Âtinâ',
      arabic:
          'Rabbenâ âtinâ fid-dünyâ haseneten ve fil-âhireti haseneten ve kınâ azâben-nâr.',
      meaning:
          'Rabbimiz! Bize dünyada iyilik, ahirette de iyilik ver ve bizi ateş azabından koru.',
    ),
    (
      title: 'Rabbi Yessir',
      arabic: 'Rabbi yessir velâ tuassir, Rabbi temmim bil-hayr.',
      meaning: 'Rabbim kolaylaştır, zorlaştırma; Rabbim hayırla tamamla.',
    ),
    (
      title: 'İlim Duası',
      arabic: 'Rabbi zidnî ilmâ.',
      meaning: 'Rabbim, ilmimi artır.',
    ),
    (
      title: 'Bağışlanma Duası',
      arabic: 'Estağfirullâhel azîm ve etûbü ileyh.',
      meaning: 'Yüce Allah’tan bağışlanma diler ve O’na tövbe ederim.',
    ),
    (
      title: 'Yolculuk Duası',
      arabic: 'Sübhânellezî sehhara lenâ hâzâ ve mâ kunnâ lehû mukrinîn.',
      meaning:
          'Bunu bizim hizmetimize veren Allah’ı noksan sıfatlardan tenzih ederiz; yoksa buna gücümüz yetmezdi.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dualar')),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _duas.length,
          itemBuilder: (context, index) {
            final dua = _duas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(dua.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dua.arabic,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(height: 1.6),
                    ),
                  ),
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text(dua.meaning, style: const TextStyle(height: 1.5)),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
