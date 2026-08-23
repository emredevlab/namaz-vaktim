import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/design/app_theme.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _duas.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return const _DuasHeaderCard();
            final dua = _duas[index - 1];
            return _DuaCard(dua: dua);
          },
        ),
      );
}

class _DuasHeaderCard extends StatelessWidget {
  const _DuasHeaderCard();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: .35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -30,
                child: Icon(
                  Icons.auto_stories,
                  size: 116,
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dualar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Okunuş ve anlamlarıyla namaz duaları',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.dua});

  final ({String title, String arabic, String meaning}) dua;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.menu_book_outlined),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 26,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dua.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy_outlined, color: AppTheme.gold),
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
              style: TextStyle(
                color: isDark ? AppTheme.goldSoft : AppTheme.primaryDeep,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                height: 1.7,
              ),
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
  }
}
