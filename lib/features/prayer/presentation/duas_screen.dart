import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/design/app_theme.dart';

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  static const _categories = <String>[
    'Namaz',
    'Günlük Hayat',
    'Korunma',
    'Dini Günler',
  ];

  static const _duas = <({String title, String arabic, String meaning, String category})>[
    // --- NAMAZ ---
    (
      title: 'İftitah Duası (Sübhâneke)',
      arabic:
          'Sübhâneke Allâhümme ve bihamdik, ve bârake-smük ve teâlâ ceddük, ve lâ ilâhe ğayrük.',
      meaning:
          'Allah’ım! Seni noksan sıfatlardan tenzih eder, sana hamd ederim. Adın mübarektir, şanın yücedir. Senden başka ilah yoktur.',
      category: 'Namaz',
    ),
    (
      title: 'Ettehiyyatü',
      arabic:
          'Ettehiyyâtü lillâhi ves-salevâtü vet-tayyibât. Esselâmü aleyke eyyuhen-nebiyyü ve rahmetullâhi ve berekâtüh. Esselâmü aleynâ ve alâ ibâdillâhis-sâlihîn. Eşhedü ellâ ilâhe illallâh ve eşhedü enne Muhammeden abdühû ve resûlüh.',
      meaning:
          'Bütün ibadetler, güzel sözler ve ameller Allah’adır. Ey Peygamber! Allah’ın selâmı, rahmeti ve bereketleri üzerine olsun. Selâm bizim üzerimize ve Allah’ın saliha kulları üzerine olsun. Allah’tan başka ilah olmadığına, Muhammed’in O’nun kulu ve elçisi olduğuna şahitlik ederim.',
      category: 'Namaz',
    ),
    (
      title: 'Salavat-ı İbrâhîmiyye (Ka’dede)',
      arabic:
          'Allâhümme salli alâ Muhammedin ve alâ âli Muhammed, kemâ salleyte alâ İbrâhîme ve alâ âli İbrâhîm. İnneke hamîdün mecid. Allâhümme bârik alâ Muhammedin ve alâ âli Muhammed, kemâ bârekte alâ İbrâhîme ve alâ âli İbrâhîm. İnneke hamîdün mecid.',
      meaning:
          'Allah’ım! Muhammed’e ve Muhammed’in âline, İbrahim’e ve İbrahim’in âline salat ettiğin gibi salat eyle. Şüphesiz Sen övülmüşsün, şereflisin. Allah’ım! Muhammed’e ve Muhammed’in âline, İbrahim’e ve İbrahim’in âline bereket verdiğin gibi bereket ihsan eyle. Şüphesiz Sen övülmüşsün, şereflisin.',
      category: 'Namaz',
    ),
    (
      title: 'Salavat',
      arabic:
          'Allâhümme salli ve sellim alâ seyyidinâ Muhammedin ve alâ âlihî.',
      meaning:
          'Allah’ım! Efendimiz Muhammed’e ve onun âline salat ve selam et.',
      category: 'Namaz',
    ),
    (
      title: 'Kunut Duası',
      arabic:
          'Allâhümme innâ nesteînüke ve nestağfirük. Ve nestehdîk ve nü’minü bik. Ve netûbü ileyk. Vetevekkelna aleyke ve süknâ lekel-hayra küllehû eşşükre leke. Nenşedü bike min külli şerrin senecrîk. Allâhümme iyyâke nabüdü ve leke nüsallî ve nescüdü. Ve ileyke nes’â ve nahfid. Necû rahmetek. Ve nahşâ azâbek. İnnel azâbe bilküffâri mulhık.',
      meaning:
          'Allah’ım! Senden yardım ve bağışlanma dileriz. Senden doğru yolu ister, sana iman eder ve sana yöneliriz. Sana güvenir ve verdiklerin için sana şükrederiz. Gazabını gerektirecek kötülüklerden sana sığınırız. Allah’ım! Yalnız sana kulluk ederiz; yalnız sana namaz kılar ve secde ederiz. Yalnız sana koşar ve sana yaklaştıracak ameller işleriz. Rahmetini umar, azabından korkarız. Çünkü azabın ancak kâfirlere dokunur.',
      category: 'Namaz',
    ),
    (
      title: 'Secde Duası (Sübhâne Rabbiyel-A’lâ)',
      arabic: 'Sübhâne Rabbiyel-a’lâ.',
      meaning: 'En Yüce olan Rabbim, tüm eksikliklerden uzaktır.',
      category: 'Namaz',
    ),
    (
      title: 'Rabbenâğfirli (Namaz Sonrası)',
      arabic: 'Rabbenâğfir lî veli-vâlideyye ve lilmü’minîne yevme yekûmul-hisâb.',
      meaning:
          'Rabbimiz! Beni, annemi-babamı ve hesabın kurulduğu günde bütün müminleri bağışla.',
      category: 'Namaz',
    ),
    (
      title: 'Rabbenâ Âtinâ',
      arabic:
          'Rabbenâ âtinâ fid-dünyâ haseneten ve fil-âhireti haseneten ve kınâ azâben-nâr.',
      meaning:
          'Rabbimiz! Bize dünyada iyilik, ahirette de iyilik ver ve bizi ateş azabından koru.',
      category: 'Namaz',
    ),
    (
      title: 'Sana Güvenme Duası (Rabbenâ Lâ Tü’ziz Zenûbenâ)',
      arabic:
          'Rabbenâ lâ tü’ziz zenûbenâ ve lâ tüdirrnâ bizünûbinellezîne âlev min kablinâ. Ve lâ tühamilnâ mâlâ tâkatelenâ bih. Va’fü annâ vağfir lenâ verhamnâ. Ente mevlânefensurnâ alel-kavmil-kâfirîn.',
      meaning:
          'Rabbimiz! Günahlarımızı bize yükleme; bizden önce yaşayanların günahlarını da boynumuza yükleme. Gücümüzün yetmediği şeylerle bizi sorumlu tutma. Bizi affet, bağışla ve rahmetine mazhar eyle. Sen bizim velimizsin; kâfir topluluğa karşı bize yardım et.',
      category: 'Namaz',
    ),
    (
      title: 'Abdest Duası',
      arabic:
          'Eşhedü ellâ ilâhe illallâhü vahdehû lâ şerîke leh, ve eşhedü enne Muhammeden abdühu ve resûlüh. Allâhümmerc’nî minev-tevvâbîn vec’alnî minel-mütetahhirîn.',
      meaning:
          'Allah’tan başka ilah olmadığına, O’nun tek olduğunu ve ortağının bulunmadığını; Muhammed’in de O’nun kulu ve elçisi olduğuna şahitlik ederim. Allah’ım! Beni tövbe edenlerden ve temizlenenlerden kıl.',
      category: 'Namaz',
    ),
    (
      title: 'Ezan Sonrası Dua',
      arabic:
          'Allâhümme rabbe hâzihid-da’vetit-tâmme ves-salâtil-âime, âti Muhammedenel-vesîlete vel-fadîle, veb’ashü makâmen mahmûdenillezî vaadteh.',
      meaning:
          'Allah’ım! Bu tam davetin ve kılınacak namazın Rabb’i! Muhammed’e vesile ve fazileti ver; onu vadettiğin Makam-ı Mahmud’a ulaştır.',
      category: 'Namaz',
    ),
    (
      title: 'Rabbi Yessir',
      arabic: 'Rabbi yessir velâ tuassir, Rabbi temmim bil-hayr.',
      meaning: 'Rabbim kolaylaştır, zorlaştırma; Rabbim hayırla tamamla.',
      category: 'Namaz',
    ),
    (
      title: 'İlim Duası',
      arabic: 'Rabbi zidnî ilmâ.',
      meaning: 'Rabbim, ilmimi artır.',
      category: 'Namaz',
    ),
    (
      title: 'Bağışlanma Duası',
      arabic: 'Estağfirullâhel azîm ve etûbü ileyh.',
      meaning: 'Yüce Allah’tan bağışlanma diler ve O’na tövbe ederim.',
      category: 'Namaz',
    ),
    (
      title: 'Yemek Duası',
      arabic: 'Bismillâhirrahmânirrahîm',
      meaning: 'Rahmân ve Rahîm olan Allah’ın adıyla.',
      category: 'Namaz',
    ),
    (
      title: 'Yolculuk Duası',
      arabic: 'Sübhânellezî sehhara lenâ hâzâ ve mâ kunnâ lehû mukrinîn.',
      meaning:
          'Bunu bizim hizmetimize veren Allah’ı noksan sıfatlardan tenzih ederiz; yoksa buna gücümüz yetmezdi.',
      category: 'Namaz',
    ),

    // --- GÜNLÜK HAYAT ---
    (
      title: 'Uyku Öncesi Dua',
      arabic: 'Bismikel-lâhümme emûtü ve ehyâ.',
      meaning: 'Allah’ım! Adınla ölür (uyurum) ve adınla dirilir (uyanı)rım.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Uyanınca Okunacak Dua',
      arabic: 'Elhamdülillâhillezî ehyânâ ba’de mâ emâtenâ ve ileyhin-nüşûr.',
      meaning:
          'Bizi ölümden (uykudan) sonra dirilten Allah’a hamdolsun; dönüş yalnız O’nadır.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Eve Girerken Okunacak Dua',
      arabic: 'Bismillâhi velecnâ ve bismillâhi harecnâ ve alâ rabbina tevekkelnâ.',
      meaning: 'Allah’ın adıyla girdik, Allah’ın adıyla çıktık ve Rabbimize güvendik.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Evden Çıkarken Okunacak Dua',
      arabic: 'Bismillâhi tevekkektü alellâh, ve lâ havle ve lâ kuvvete illâ billâh.',
      meaning:
          'Allah’ın adıyla, Allah’a tevekkül ederek (eve) çıkıyorum; güç ve kuvvet yalnız Allah’tandır.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Yemek Sonrası Dua',
      arabic: 'Elhamdülillâhillezî et’amenâ ve sekâne ve cealenâ müslimîn.',
      meaning: 'Bizi yediren, içiren ve Müslüman kılan Allah’a hamdolsun.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Su İçerken Okunacak Dua',
      arabic: 'Bismillâh ... Elhamdülillâh.',
      meaning:
          'Su içerken başında “Bismillâh”, bitince “Elhamdülillâh” denir. Suyu üç nefeste ve oturarak içmek sünnettir.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Tuvaletten Çıkış Duası',
      arabic: 'Elhamdülillâhillezî azhebe annil-ezâ ve âfânî.',
      meaning: 'Benden eziyeti gideren ve bana afiyet veren Allah’a hamdolsun.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Yeni Ay Görünce Okunacak Dua',
      arabic:
          'Allâhümme ehillet-hü aleynâ bil-emni vel-îmân, ves-selâmeti vel-islâm, ve lit-tavfîki mâ tuhibbü ver-tardâ. Rabbünâ ve Rabbükellâh.',
      meaning:
          'Allah’ım! Bu ayı üzerimize güven ve iman, selamet ve İslam ile getir; sevdiğin ve hoşnut olacağın işlerde bize başarı ihsan eyle. Bizim de Rabb’in, senin de Rabb’in olan Allah’tır.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Borçtan Kurtulma Duası',
      arabic:
          'Allâhümmefkıfnî bihalâlike an harâmike, ve eğninî bifadlike ammen sivâk.',
      meaning:
          'Allah’ım! Helalinle beni haramından koru, lütuf ve ihsanınla da senden başkasına muhtaç etme.',
      category: 'Günlük Hayat',
    ),
    (
      title: 'Hasta Ziyareti Duası',
      arabic: 'Lâ ba’s, tahûrun in şâallâh.',
      meaning:
          'Zararı yok; inşaallah bu hastalık senin günahlarına keffaret olacak bir temizliktir.',
      category: 'Günlük Hayat',
    ),

    // --- KORUNMA ---
    (
      title: 'Âyetü’l-Kürsî',
      arabic:
          'Allâhü lâ ilâhe illâ hüvel-hayyul-kayyûm. Lâ te’huzühû sinetün ve lâ nevm. Lehû mâ fis-semâvâti ve mâ fil-ard ... (Âyetü’l-Kürsî’nin tamamı için mushafınıza bakın.)',
      meaning:
          'Allah’tan başka ilah yoktur; O, daima diridir, her şeyin varlığı O’na bağlıdır. O’nu ne uyku tutar ne uyuklama. Göklerdeki ve yerdeki her şey O’nundur ... (devamı için mushafınıza bakın.) Sabah-akşam ve her namaz sonrası okunması, şeytanın şerrinden korunmayı sağlar.',
      category: 'Korunma',
    ),
    (
      title: 'Felak Suresi',
      arabic:
          'Kul e’ûzü birabbil-felak. Min şerri mâ halâk. Ve min şerri gâsikın izâ vekab. Ve min şerrin-neffâsâti fil-ukad. Ve min şerri hâsidin izâ hased.',
      meaning:
          'De ki: Sabahın Rabbine sığırım. Yarattığı şeylerin şerrinden, karanlık çökünce gecenin şerrinden, düğümlere üfürüp büyü yapanların şerrinden ve kıskandığı zaman kıskanç kişinin şerrinden.',
      category: 'Korunma',
    ),
    (
      title: 'Nâs Suresi',
      arabic:
          'Kul e’ûzü birabbin-nâs. Melikin-nâs. İlâhin-nâs. Min şerril-vesvâsil-hannâs. Ellezî yüvesvisü fî sudûrin-nâs. Minel-cinneti ven-nâs.',
      meaning:
          'De ki: İnsanların Rabb’ine, insanların melikine (hükümdarına), insanların ilahına sığırım; insanların göğüslerine vesvese veren, çekip kaçan o şeytanın şerrinden — cinlerden ve insanlardan.',
      category: 'Korunma',
    ),
    (
      title: 'Kötülüklerden Korunma Duası',
      arabic:
          'Bismillâhillezî lâ yedurru measmi şey’in erdâ arzuhû ve lâ fis-semâi hüves-semîul-alîm.',
      meaning:
          'O çok işiten, çok bilen Allah’ın adıyla! Yerde veya gökte hiçbir şey (O’nun adını anan kimseye) zarar veremez. Gün içinde üç kez okunması tavsiye edilir.',
      category: 'Korunma',
    ),
    (
      title: 'Eûzü Kelimesi (Yaratıkların Şerrinden Sığınma)',
      arabic: 'E’ûzü bikelimâtillâhit-tâm-mâti min şerri mâ halâk.',
      meaning: 'Yarattığı şeylerin şerrinden, Allah’ın eksiksiz sözlerine sığınırım.',
      category: 'Korunma',
    ),
    // --- DİNİ GÜNLER ---
    (
      title: 'Mevlid Kandili Duası',
      arabic:
          'Yâ Rabbî! Sevgili Peygamberine ümmet olma şerefine erdirdiğin için sana hamd olsun. Onun şefaatine nail eyle ve güzel ahlâkıyla ahlâklanmayı bizlere nasîp et. Âmîn.',
      meaning:
          'Mevlid Kandili’nde Peygamber Efendimize salât ü selâm getirilmesi, Kur’ân okunması ve dua edilmesi müstehaptır.',
      category: 'Dini Günler',
    ),
    (
      title: 'Cuma Günü Duası',
      arabic: 'Allâhümme salli alâ Muhammedin ve alâ âli Muhammed.',
      meaning:
          'Cuma günü Kehf Suresi okumak, bol salavat getirmek ve dua etmek müstehaptır. Cuma saatinde kabul edilmiş bir an vardır.',
      category: 'Dini Günler',
    ),
    (
      title: 'Kadir Gecesi Duası',
      arabic:
          'Allâhümme inneke afüvvün kerîmün tühibbü’l-afve fa’fu annî.',
      meaning:
          'Allah’ım! Sen affedicisin, affı seversin; beni de affet. (Kadir Gecesi’nde Peygamberimizin okuttuğu dua.)',
      category: 'Dini Günler',
    ),
    (
      title: 'Arefe Duası',
      arabic:
          'Lâ ilâhe illallâhü vahdehû lâ şerîke leh. Lehü’l-mülkü ve lehü’l-hamdü ve hüve alâ külli şey’in kadîr.',
      meaning: 'Arefe gününde bu kelime-i tevhidi bolca zikretmek faziletlidir.',
      category: 'Dini Günler',
    ),
    (
      title: 'Aşure Günü Duası',
      arabic: 'Hasbünallâhü ve ni’mel-vekîl. Elhamdü lillâhi alâ külli hâlin.',
      meaning:
          'Aşure Günü’nde zikir, sadaka ve akraba ziyareti tavsiye edilir.',
      category: 'Dini Günler',
    ),
    (
      title: 'Berat Kandili Duası',
      arabic:
          'Elhamdü lillâhi Rabbi’l-âlemîn. Allâhümme inneke afüvvün kerîmün tühibbü’l-afve fa’fu annî.',
      meaning:
          'Berat Kandili’nde af dilemek ve Kur’ân tilâveti etmek müstehaptır.',
      category: 'Dini Günler',
    ),
    (
      title: 'Miraç Kandili Duası',
      arabic:
          'Sübhânallâhi ve’l-hamdü lillâhi ve lâ ilâhe illallâhü vallâhü ekber.',
      meaning:
          'Miraç Kandili’nde namaz kılmak, zikretmek, tövbe ve istiğfar etmek müstehaptır.',
      category: 'Dini Günler',
    ),
    (
      title: 'Hicri Yıl Başı Duası',
      arabic:
          'Yâ Rabbî! Bu hicrî yılı imânımızı tazelememize ve sâlih amellere vesîle eyle. Âmîn.',
      meaning: 'Hicri yılın ilk günü dua etmek, hayra başlamanın işaretidir.',
      category: 'Dini Günler',
    ),
  ];

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  String? _selectedCategory;

  List<({String title, String arabic, String meaning, String category})>
  get _filteredDuas => _selectedCategory == null
      ? DuasScreen._duas
      : DuasScreen._duas
          .where((dua) => dua.category == _selectedCategory)
          .toList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dualar')),
        body: ListView.builder(
          padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      MediaQuery.of(context).padding.bottom + 24,
    ),
          itemCount: _filteredDuas.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return const _DuasHeaderCard();
            if (index == 1) return _buildFilterChips(context);
            return _DuaCard(dua: _filteredDuas[index - 2]);
          },
        ),
      );

  Widget _buildFilterChips(BuildContext context) {
    Widget buildChip(String label, VoidCallback onTap, bool selected) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            checkmarkColor: Colors.white,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
        );

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
          buildChip(
            'Tümü',
            () => setState(() => _selectedCategory = null),
            _selectedCategory == null,
          ),
          for (final category in DuasScreen._categories)
            buildChip(
              category,
              () => setState(() {
                _selectedCategory =
                    _selectedCategory == category ? null : category;
              }),
              _selectedCategory == category,
            ),
        ],
      ),
    );
  }
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
                      'Okunuş ve anlamlarıyla dualar: Namaz, Günlük Hayat, Korunma',
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

  final ({String title, String arabic, String meaning, String category}) dua;

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
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              dua.category,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold.withValues(alpha: isDark ? .9 : .85),
              ),
            ),
          ),
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
