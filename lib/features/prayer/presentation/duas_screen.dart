import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    (
      title: 'Ettehiyyatü',
      arabic:
          'Ettehiyyâtü lillâhi ves-salevâtü vet-tayyibât. Esselâmü aleyke eyyuhen-nebiyyü ve rahmetullâhi ve berekâtüh. Esselâmü aleynâ ve alâ ibâdillâhis-sâlihîn. Eşhedü ellâ ilâhe illallâh ve eşhedü enne Muhammeden abdühû ve resûlüh.',
      meaning:
          'Bütün ibadetler, güzel sözler ve ameller Allah’adır. Ey Peygamber! Allah’ın selâmı, rahmeti ve bereketleri üzerine olsun. Selâm bizim üzerimize ve Allah’ın saliha kulları üzerine olsun. Allah’tan başka ilah olmadığına, Muhammed’in O’nun kulu ve elçisi olduğuna şahitlik ederim.',
    ),
    (
      title: 'Tahiyyat Sonrası Salavat',
      arabic:
          'Allâhümme salli alâ Muhammedin ve alâ âli Muhammed, kemâ salleyte alâ İbrâhîme ve alâ âli İbrâhîm. İnneke hamîdün mecid. Allâhümme bârik alâ Muhammedin ve alâ âli Muhammed, kemâ bârekte alâ İbrâhîme ve alâ âli İbrâhîm. İnneke hamîdün mecid.',
      meaning:
          'Allah’ım! Muhammed’e ve Muhammed’in âline, İbrahim’e ve İbrahim’in âline salat ettiğin gibi salat eyle. Şüphesiz Sen övülmüşsün, şereflisin. Allah’ım! Muhammed’e ve Muhammed’in âline, İbrahim’e ve İbrahim’in âline bereket verdiğin gibi bereket ihsan eyle. Şüphesiz Sen övülmüşsün, şereflisin.',
    ),
    (
      title: 'Salavat',
      arabic:
          'Allâhümme salli ve sellim alâ seyyidinâ Muhammedin ve alâ âlihî.',
      meaning:
          'Allah’ım! Efendimiz Muhammed’e ve onun âline salat ve selam et.',
    ),
    (
      title: 'Kunut Duası',
      arabic:
          'Allâhümme innâ nesteînüke ve nestağfirük. Ve nestehdîk ve nü’minü bik. Ve netûbü ileyk. Vetevekkelna aleyke ve süknâ lekel-hayra küllehû eşşükre leke. Nenşedü bike min külli şerrin senecrîk. Allâhümme iyyâke nabüdü ve leke nüsallî ve nescüdü. Ve ileyke nes’â ve nahfid. Necû rahmetek. Ve nahşâ azâbek. İnnel azâbe bilküffâri mulhık.',
      meaning:
          'Allah’ım! Senden yardım ve bağışlanma dileriz. Senden doğru yolu ister, sana iman eder ve sana yöneliriz. Sana güvenir ve verdiklerin için sana şükrederiz. Gazabını gerektirecek kötülüklerden sana sığınırız. Allah’ım! Yalnız sana kulluk ederiz; yalnız sana namaz kılar ve secde ederiz. Yalnız sana koşar ve sana yaklaştıracak ameller işleriz. Rahmetini umar, azabından korkarız. Çünkü azabın ancak kâfirlere dokunur.',
    ),
    (
      title: 'Secde Duası',
      arabic: 'Sübhâne Rabbiyel-a’lâ.',
      meaning: 'En Yüce olan Rabbim, tüm eksikliklerden uzaktır.',
    ),
    (
      title: 'Sana Güvenme Duası (Rabbenâ Lâ Tü’ziz Zenûbenâ)',
      arabic:
          'Rabbenâ lâ tü’ziz zenûbenâ ve lâ tüdirrnâ bizünûbinellezîne âlev min kablinâ. Ve lâ tühamilnâ mâlâ tâkatelenâ bih. Va’fü annâ vağfir lenâ verhamnâ. Ente mevlânefensurnâ alel-kavmil-kâfirîn.',
      meaning:
          'Rabbimiz! Günahlarımızı bize yükleme; bizden önce yaşayanların günahlarını da boynumuza yükleme. Gücümüzün yetmediği şeylerle bizi sorumlu tutma. Bizi affet, bağışla ve rahmetine mazhar eyle. Sen bizim velimizsin; kâfir topluluğa karşı bize yardım et.',
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
                trailing: IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Panoya kopyala',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '${dua.title}\n\n${dua.arabic}\n\n${dua.meaning}',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Panoya kopyalandı')),
                    );
                  },
                ),
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
