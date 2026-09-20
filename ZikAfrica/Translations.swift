import Foundation

/// Table de traduction centrale. Une entrée par clé, une valeur par langue.
/// Note qualité : anglais, arabe et portugais ont été traduits avec une bonne
/// confiance. Le swahili est fourni à titre indicatif — une relecture par un
/// locuteur natif est recommandée avant publication si ce marché est stratégique.
enum Translations {
    static let table: [String: [AppLanguage: String]] = [

        // MARK: - Règles du jeu
        "rules_title": [
            .french: "🎮 RÈGLES DU JEU",
            .english: "🎮 GAME RULES",
            .arabic: "🎮 قواعد اللعبة",
            .portuguese: "🎮 REGRAS DO JOGO",
            .swahili: "🎮 KANUNI ZA MCHEZO"
        ],
        "rules_step1": [
            .french: "Scanne une carte ZikAfrica.",
            .english: "Scan a ZikAfrica card.",
            .arabic: "امسح بطاقة ZikAfrica ضوئيًا.",
            .portuguese: "Digitaliza um cartão ZikAfrica.",
            .swahili: "Skani kadi ya ZikAfrica."
        ],
        "rules_step2": [
            .french: "La musique se lance.",
            .english: "The music starts.",
            .arabic: "تبدأ الموسيقى.",
            .portuguese: "A música começa a tocar.",
            .swahili: "Muziki unaanza kucheza."
        ],
        "rules_step3": [
            .french: "Devine le titre, l’artiste ou l’année.",
            .english: "Guess the title, artist, or year.",
            .arabic: "خمّن العنوان أو الفنان أو السنة.",
            .portuguese: "Adivinha o título, o artista ou o ano.",
            .swahili: "Kisia jina la wimbo, msanii, au mwaka."
        ],
        "rules_step4": [
            .french: "Gagne 3, 2 ou 1 Beats.",
            .english: "Win 3, 2, or 1 Beats.",
            .arabic: "اربح 3 أو 2 أو 1 من نقاط Beats.",
            .portuguese: "Ganha 3, 2 ou 1 Beats.",
            .swahili: "Shinda Beats 3, 2, au 1."
        ],
        "rules_step5": [
            .french: "Le meilleur score gagne.",
            .english: "The highest score wins.",
            .arabic: "صاحب أعلى نتيجة يفوز.",
            .portuguese: "A maior pontuação vence.",
            .swahili: "Aliye na alama nyingi zaidi ndiye mshindi."
        ],
        "close_button": [
            .french: "FERMER",
            .english: "CLOSE",
            .arabic: "إغلاق",
            .portuguese: "FECHAR",
            .swahili: "FUNGA"
        ],

        // MARK: - Carte révélée
        "reveal_title": [
            .french: "🏆 CARTE RÉVÉLÉE",
            .english: "🏆 CARD REVEALED",
            .arabic: "🏆 تم كشف البطاقة",
            .portuguese: "🏆 CARTÃO REVELADO",
            .swahili: "🏆 KADI IMEFUNULIWA"
        ],
        "reveal_track_label": [
            .french: "TITRE",
            .english: "TITLE",
            .arabic: "العنوان",
            .portuguese: "TÍTULO",
            .swahili: "JINA LA WIMBO"
        ],
        "reveal_artist_label": [
            .french: "ARTISTE",
            .english: "ARTIST",
            .arabic: "الفنان",
            .portuguese: "ARTISTA",
            .swahili: "MSANII"
        ],
        "reveal_year_label": [
            .french: "ANNÉE",
            .english: "YEAR",
            .arabic: "السنة",
            .portuguese: "ANO",
            .swahili: "MWAKA"
        ],
        "reveal_points_track": [
            .french: "+3 Beats", .english: "+3 Beats", .arabic: "+3 Beats",
            .portuguese: "+3 Beats", .swahili: "+3 Beats"
        ],
        "reveal_points_artist": [
            .french: "+2 Beats", .english: "+2 Beats", .arabic: "+2 Beats",
            .portuguese: "+2 Beats", .swahili: "+2 Beats"
        ],
        "reveal_points_year": [
            .french: "+1 Beat", .english: "+1 Beat", .arabic: "+1 Beat",
            .portuguese: "+1 Beat", .swahili: "+1 Beat"
        ],
        "reveal_footer": [
            .french: "Attribuez les jetons Beats correspondants",
            .english: "Hand out the matching Beats tokens",
            .arabic: "وزّع رموز Beats المطابقة",
            .portuguese: "Distribui os tokens Beats correspondentes",
            .swahili: "Gawa vitufe vya Beats vinavyolingana"
        ],

        // MARK: - Choix de plateforme
        "platform_choice_title": [
            .french: "🎧 CHOISIS TA PLATEFORME",
            .english: "🎧 CHOOSE YOUR PLATFORM",
            .arabic: "🎧 اختر منصتك",
            .portuguese: "🎧 ESCOLHE A TUA PLATAFORMA",
            .swahili: "🎧 CHAGUA JUKWAA LAKO"
        ],
        "no_app_title": [
            .french: "🎧 INSTALLE UNE APP MUSICALE",
            .english: "🎧 INSTALL A MUSIC APP",
            .arabic: "🎧 ثبّت تطبيق موسيقى",
            .portuguese: "🎧 INSTALA UMA APP DE MÚSICA",
            .swahili: "🎧 SAKINISHA APU YA MUZIKI"
        ],
        "no_app_subtitle": [
            .french: "Pour jouer avec ZikAfrica, installe l’une de ces apps musicales — c’est elle qui fait tourner la musique pendant la partie.",
            .english: "To play ZikAfrica, install one of these music apps — it's what plays the music during the game.",
            .arabic: "للعب مع ZikAfrica، ثبّت أحد تطبيقات الموسيقى هذه — فهو ما يشغّل الموسيقى أثناء اللعب.",
            .portuguese: "Para jogar ZikAfrica, instala uma destas apps de música — é ela que toca a música durante o jogo.",
            .swahili: "Ili kucheza ZikAfrica, sakinisha moja ya apu hizi za muziki — ndiyo itakayocheza muziki wakati wa mchezo."
        ],
        "later_button": [
            .french: "Plus tard",
            .english: "Later",
            .arabic: "لاحقًا",
            .portuguese: "Mais tarde",
            .swahili: "Baadaye"
        ],

        // MARK: - Barre du haut
        "top_rules": [
            .french: "RÈGLES", .english: "RULES", .arabic: "القواعد",
            .portuguese: "REGRAS", .swahili: "KANUNI"
        ],
        "top_scores_live": [
            .french: "SCORES LIVE", .english: "LIVE SCORES", .arabic: "النتائج المباشرة",
            .portuguese: "PONTUAÇÕES AO VIVO", .swahili: "ALAMA MOJA KWA MOJA"
        ],
        "top_scores": [
            .french: "SCORES", .english: "SCORES", .arabic: "النتائج",
            .portuguese: "PONTUAÇÕES", .swahili: "ALAMA"
        ],
        "top_settings": [
            .french: "AJUST.", .english: "SETTINGS", .arabic: "الإعدادات",
            .portuguese: "AJUSTES", .swahili: "MIPANGILIO"
        ],

        // MARK: - Boutons de jeu
        "button_replay": [
            .french: "Rejouer", .english: "Replay", .arabic: "إعادة اللعب",
            .portuguese: "Repetir", .swahili: "Cheza tena"
        ],
        "button_reveal": [
            .french: "Révéler", .english: "Reveal", .arabic: "كشف",
            .portuguese: "Revelar", .swahili: "Funua"
        ],
        "button_new_game": [
            .french: "Nouvelle partie", .english: "New game", .arabic: "لعبة جديدة",
            .portuguese: "Novo jogo", .swahili: "Mchezo mpya"
        ],
        "no_platform": [
            .french: "Aucune plateforme", .english: "No platform", .arabic: "لا توجد منصة",
            .portuguese: "Nenhuma plataforma", .swahili: "Hakuna jukwaa"
        ],

        // MARK: - Bouton scanner
        "scan_line1": [
            .french: "SCANNER", .english: "SCAN", .arabic: "امسح",
            .portuguese: "DIGITALIZAR", .swahili: "SKANI"
        ],
        "scan_line2": [
            .french: "UNE CARTE", .english: "A CARD", .arabic: "بطاقة",
            .portuguese: "UM CARTÃO", .swahili: "KADI"
        ],

        // MARK: - Cartes d'action (Scanne / Écoute / Devine)
        "card_scan_title": [
            .french: "SCANNE", .english: "SCAN", .arabic: "امسح",
            .portuguese: "DIGITALIZA", .swahili: "SKANI"
        ],
        "card_scan_subtitle": [
            .french: "Scanne une carte", .english: "Scan a card", .arabic: "امسح بطاقة",
            .portuguese: "Digitaliza um cartão", .swahili: "Skani kadi"
        ],
        "card_listen_title": [
            .french: "ÉCOUTE", .english: "LISTEN", .arabic: "استمع",
            .portuguese: "OUVE", .swahili: "SIKILIZA"
        ],
        "card_listen_subtitle": [
            .french: "La musique se lance", .english: "The music starts", .arabic: "تبدأ الموسيقى",
            .portuguese: "A música começa", .swahili: "Muziki unaanza"
        ],
        "card_guess_title": [
            .french: "DEVINE", .english: "GUESS", .arabic: "خمّن",
            .portuguese: "ADIVINHA", .swahili: "KISIA"
        ],
        "card_guess_subtitle": [
            .french: "Trouve le titre", .english: "Find the title", .arabic: "اكتشف العنوان",
            .portuguese: "Descobre o título", .swahili: "Tafuta jina la wimbo"
        ],

        // MARK: - Compteur de cartes (approximatif hors français : pluriel simplifié)
        "scan_counter_singular_format": [
            .french: "%d carte jouée",
            .english: "%d card played",
            .arabic: "تم لعب بطاقة %d",
            .portuguese: "%d carta jogada",
            .swahili: "Kadi %d imechezwa"
        ],
        "scan_counter_plural_format": [
            .french: "%d cartes jouées",
            .english: "%d cards played",
            .arabic: "تم لعب %d بطاقات",
            .portuguese: "%d cartas jogadas",
            .swahili: "Kadi %d zimechezwa"
        ],

        // MARK: - Alerte : Apple Music recommandé
        "apple_music_recommend_title": [
            .french: "Apple Music recommandé",
            .english: "Apple Music recommended",
            .arabic: "يُنصح باستخدام Apple Music",
            .portuguese: "Apple Music recomendado",
            .swahili: "Apple Music inapendekezwa"
        ],
        "apple_music_recommend_message": [
            .french: "Avec Apple Music, chaque carte scannée déclenche sa musique instantanément, sans interruption ni temps mort — pour rester à fond dans le jeu et garder tout le suspense. Tu peux continuer sans, mais Apple Music offre la meilleure expérience ZikAfrica.",
            .english: "With Apple Music, every scanned card starts its music instantly, with no interruption or dead time — so you stay fully in the game and keep all the suspense. You can continue without it, but Apple Music gives you the best ZikAfrica experience.",
            .arabic: "مع Apple Music، تبدأ موسيقى كل بطاقة تُمسح ضوئيًا فورًا، دون انقطاع أو وقت ضائع، لتبقى منغمسًا في اللعبة وتحافظ على كل الإثارة. يمكنك المتابعة بدونه، لكن Apple Music يمنحك أفضل تجربة على ZikAfrica.",
            .portuguese: "Com a Apple Music, cada cartão digitalizado toca a sua música instantaneamente, sem interrupções nem tempos mortos — para ficares totalmente dentro do jogo e manteres todo o suspense. Podes continuar sem, mas a Apple Music oferece a melhor experiência ZikAfrica.",
            .swahili: "Kwa Apple Music, kila kadi inayoskaniwa huanzisha muziki wake papo hapo, bila kukatizwa wala muda uliopotea — ili ubaki kwenye mchezo kikamilifu na kuendeleza msisimko wote. Unaweza kuendelea bila hiyo, lakini Apple Music inatoa uzoefu bora zaidi wa ZikAfrica."
        ],
        "download_apple_music_button": [
            .french: "Télécharger Apple Music",
            .english: "Download Apple Music",
            .arabic: "تنزيل Apple Music",
            .portuguese: "Transferir Apple Music",
            .swahili: "Pakua Apple Music"
        ],
        "continue_button": [
            .french: "Continuer", .english: "Continue", .arabic: "متابعة",
            .portuguese: "Continuar", .swahili: "Endelea"
        ],

        // MARK: - Alerte : impossible d'ouvrir la plateforme
        "platform_open_error_title": [
            .french: "Impossible d’ouvrir la plateforme",
            .english: "Couldn't open the platform",
            .arabic: "تعذّر فتح المنصة",
            .portuguese: "Não foi possível abrir a plataforma",
            .swahili: "Imeshindwa kufungua jukwaa"
        ],
        "platform_open_error_message": [
            .french: "Vérifie que l’application musicale sélectionnée est installée.",
            .english: "Check that the selected music app is installed.",
            .arabic: "تأكد من تثبيت تطبيق الموسيقى المحدد.",
            .portuguese: "Verifica se a app de música selecionada está instalada.",
            .swahili: "Hakikisha apu ya muziki uliyochagua imesakinishwa."
        ],

        // MARK: - Alerte : abonnement Apple Music requis
        "apple_music_subscription_title": [
            .french: "Abonnement Apple Music requis",
            .english: "Apple Music subscription required",
            .arabic: "يلزم اشتراك في Apple Music",
            .portuguese: "Subscrição Apple Music necessária",
            .swahili: "Unahitaji usajili wa Apple Music"
        ],
        "apple_music_subscription_message": [
            .french: "Apple Music est installé, mais aucun abonnement actif ne permet de lire le titre complet. Abonne-toi à Apple Music (ou à Spotify Premium, qui fonctionne aussi) pour profiter pleinement de ZikAfrica. En attendant, ZikAfrica continue automatiquement avec un extrait de 30 secondes.",
            .english: "Apple Music is installed, but no active subscription allows playing the full track. Subscribe to Apple Music (or Spotify Premium, which also works) to fully enjoy ZikAfrica. In the meantime, ZikAfrica automatically continues with a 30-second preview.",
            .arabic: "تطبيق Apple Music مثبّت، لكن لا يوجد اشتراك فعّال يسمح بتشغيل المقطوعة كاملة. اشترك في Apple Music (أو Spotify Premium الذي يعمل أيضًا) للاستمتاع الكامل بـ ZikAfrica. في هذه الأثناء، يتابع ZikAfrica تلقائيًا بمقطع مدته 30 ثانية.",
            .portuguese: "A Apple Music está instalada, mas nenhuma subscrição ativa permite reproduzir a faixa completa. Subscreve a Apple Music (ou o Spotify Premium, que também funciona) para aproveitares totalmente o ZikAfrica. Entretanto, o ZikAfrica continua automaticamente com um excerto de 30 segundos.",
            .swahili: "Apple Music imesakinishwa, lakini hakuna usajili unaotumika unaoruhusu kucheza wimbo mzima. Jisajili kwenye Apple Music (au Spotify Premium, ambayo pia inafanya kazi) ili kufurahia ZikAfrica kikamilifu. Wakati huo huo, ZikAfrica inaendelea kiotomatiki na kipande cha sekunde 30."
        ],

        // MARK: - Alerte : accès Apple Music bloqué
        "apple_music_auth_blocked_title": [
            .french: "Accès à Apple Music bloqué",
            .english: "Access to Apple Music blocked",
            .arabic: "تم حظر الوصول إلى Apple Music",
            .portuguese: "Acesso à Apple Music bloqueado",
            .swahili: "Ufikiaji wa Apple Music umezuiwa"
        ],
        "open_settings_button": [
            .french: "Ouvrir Réglages",
            .english: "Open Settings",
            .arabic: "فتح الإعدادات",
            .portuguese: "Abrir Definições",
            .swahili: "Fungua Mipangilio"
        ],
        "apple_music_auth_blocked_message": [
            .french: "ZikAfrica n'a pas la permission d'utiliser ta médiathèque Apple Music sur cet iPhone. Ouvre Réglages pour l'autoriser. En attendant, ZikAfrica continue automatiquement avec une autre source.",
            .english: "ZikAfrica doesn't have permission to use your Apple Music library on this iPhone. Open Settings to allow it. In the meantime, ZikAfrica automatically continues with another source.",
            .arabic: "لا يملك ZikAfrica إذنًا لاستخدام مكتبة Apple Music الخاصة بك على هذا الآيفون. افتح الإعدادات للسماح بذلك. في هذه الأثناء، يتابع ZikAfrica تلقائيًا بمصدر آخر.",
            .portuguese: "O ZikAfrica não tem permissão para usar a tua biblioteca da Apple Music neste iPhone. Abre as Definições para autorizar. Entretanto, o ZikAfrica continua automaticamente com outra fonte.",
            .swahili: "ZikAfrica haina ruhusa ya kutumia maktaba yako ya Apple Music kwenye iPhone hii. Fungua Mipangilio ili kuruhusu. Wakati huo huo, ZikAfrica inaendelea kiotomatiki na chanzo kingine."
        ],

        // MARK: - Alerte : titre indisponible sur Apple Music
        "apple_music_track_unavailable_title": [
            .french: "Titre indisponible sur Apple Music",
            .english: "Track unavailable on Apple Music",
            .arabic: "المقطوعة غير متوفرة على Apple Music",
            .portuguese: "Faixa indisponível na Apple Music",
            .swahili: "Wimbo haupatikani kwenye Apple Music"
        ],
        "apple_music_track_unavailable_message": [
            .french: "Certains titres de ZikAfrica ne sont pas dans le catalogue Apple Music. ZikAfrica bascule automatiquement sur une autre source dans ce cas, sans action de ta part.",
            .english: "Some ZikAfrica tracks aren't in the Apple Music catalog. ZikAfrica automatically switches to another source in that case, with nothing for you to do.",
            .arabic: "بعض مقطوعات ZikAfrica غير موجودة في فهرس Apple Music. في هذه الحالة، يتحوّل ZikAfrica تلقائيًا إلى مصدر آخر دون أي إجراء منك.",
            .portuguese: "Algumas faixas do ZikAfrica não estão no catálogo da Apple Music. Nesse caso, o ZikAfrica muda automaticamente para outra fonte, sem precisares de fazer nada.",
            .swahili: "Baadhi ya nyimbo za ZikAfrica hazipo kwenye orodha ya Apple Music. Katika hali hiyo, ZikAfrica hubadilisha kiotomatiki kwenda chanzo kingine, bila wewe kufanya lolote."
        ],

        // MARK: - Alerte : Spotify n'a pas pu lire ce titre
        "spotify_issue_title": [
            .french: "Spotify Premium recommandé",
            .english: "Spotify Premium recommended",
            .arabic: "يوصى باستخدام Spotify Premium",
            .portuguese: "Spotify Premium recomendado",
            .swahili: "Spotify Premium inapendekezwa"
        ],
        "spotify_issue_message": [
            .french: "Spotify est installé, mais un compte gratuit ne permet pas toujours de lire directement le titre complet dans ZikAfrica. Passe à Spotify Premium pour profiter pleinement du jeu. En attendant, ZikAfrica continue automatiquement avec un extrait de 30 secondes.",
            .english: "Spotify is installed, but a free account may not allow ZikAfrica to play the full track directly. Upgrade to Spotify Premium to fully enjoy the game. In the meantime, ZikAfrica automatically continues with a 30-second preview.",
            .arabic: "Spotify مثبّت، لكن الحساب المجاني قد لا يسمح لـ ZikAfrica بتشغيل المقطوعة كاملة مباشرة. انتقل إلى Spotify Premium للاستمتاع الكامل باللعبة. في هذه الأثناء، يتابع ZikAfrica تلقائيًا بمقطع مدته 30 ثانية.",
            .portuguese: "O Spotify está instalado, mas uma conta gratuita pode não permitir ao ZikAfrica reproduzir diretamente a faixa completa. Passa para Spotify Premium para aproveitares totalmente o jogo. Entretanto, o ZikAfrica continua automaticamente com um excerto de 30 segundos.",
            .swahili: "Spotify imesakinishwa, lakini akaunti ya bure huenda isiruhusu ZikAfrica kucheza wimbo mzima moja kwa moja. Tumia Spotify Premium ili kufurahia mchezo kikamilifu. Wakati huo huo, ZikAfrica inaendelea kiotomatiki na kipande cha sekunde 30."
        ],

        "ok_button": [
            .french: "OK", .english: "OK", .arabic: "حسنًا",
            .portuguese: "OK", .swahili: "Sawa"
        ],

        // MARK: - Écran de transition
        "transition_title": [
            .french: "LA MUSIQUE DÉMARRE",
            .english: "THE MUSIC IS STARTING",
            .arabic: "الموسيقى تبدأ",
            .portuguese: "A MÚSICA VAI COMEÇAR",
            .swahili: "MUZIKI UNAANZA"
        ],
        "transition_opening_format": [
            .french: "Ouverture de %@",
            .english: "Opening %@",
            .arabic: "جارٍ فتح %@",
            .portuguese: "A abrir %@",
            .swahili: "Inafungua %@"
        ],
        "transition_external_hint": [
            .french: "Laisse la musique jouer, puis touche l’alerte iPhone pour revenir dans ZikAfrica et deviner.",
            .english: "Let the music play, then tap the iPhone alert to return to ZikAfrica and guess.",
            .arabic: "اترك الموسيقى تعمل، ثم اضغط على تنبيه الآيفون للعودة إلى ZikAfrica والتخمين.",
            .portuguese: "Deixa a música tocar e depois toca no alerta do iPhone para voltares ao ZikAfrica e adivinhares.",
            .swahili: "Acha muziki ucheze, kisha gusa arifa ya iPhone ili urudi ZikAfrica na kukisia."
        ],

        // MARK: - Écran de retour après lecture
        "return_home": [
            .french: "Accueil", .english: "Home", .arabic: "الرئيسية",
            .portuguese: "Início", .swahili: "Mwanzo"
        ],
        "return_scan_next": [
            .french: "SCANNER LA CARTE SUIVANTE",
            .english: "SCAN THE NEXT CARD",
            .arabic: "امسح البطاقة التالية",
            .portuguese: "DIGITALIZAR O PRÓXIMO CARTÃO",
            .swahili: "SKANI KADI IFUATAYO"
        ],
        "return_replay": [
            .french: "REJOUER", .english: "REPLAY", .arabic: "إعادة اللعب",
            .portuguese: "REPETIR", .swahili: "CHEZA TENA"
        ],
        "return_reveal": [
            .french: "RÉVÉLER", .english: "REVEAL", .arabic: "كشف",
            .portuguese: "REVELAR", .swahili: "FUNUA"
        ],

        // MARK: - Popup de buzz
        "buzz_title": [
            .french: "BUZZ !", .english: "BUZZ!", .arabic: "بَظّ!",
            .portuguese: "BUZZ!", .swahili: "BUZZ!"
        ],
        "buzz_player_format": [
            .french: "%@ a buzzé en premier",
            .english: "%@ buzzed in first",
            .arabic: "%@ ضغط الجرس أولًا",
            .portuguese: "%@ carregou primeiro no buzzer",
            .swahili: "%@ amebonyeza kwanza"
        ],
        "buzz_hint": [
            .french: "Appuie ici pour gérer les points et voir l’ordre des buzzers.",
            .english: "Tap here to manage points and see the buzz order.",
            .arabic: "اضغط هنا لإدارة النقاط ومشاهدة ترتيب الضغط.",
            .portuguese: "Toca aqui para geres os pontos e veres a ordem dos buzzers.",
            .swahili: "Gusa hapa kusimamia pointi na kuona mpangilio wa buzzer."
        ],

        // MARK: - Réglages ("Ajust.")
        "settings_title": [
            .french: "AJUSTEMENTS", .english: "SETTINGS", .arabic: "الإعدادات",
            .portuguese: "AJUSTES", .swahili: "MIPANGILIO"
        ],
        "settings_scan_sound": [
            .french: "Son du scan", .english: "Scan sound", .arabic: "صوت المسح",
            .portuguese: "Som de digitalização", .swahili: "Sauti ya kuskani"
        ],
        "settings_vibration": [
            .french: "Vibrations", .english: "Vibration", .arabic: "الاهتزاز",
            .portuguese: "Vibração", .swahili: "Mtetemo"
        ],
        "settings_change_platform": [
            .french: "Changer de plateforme", .english: "Change platform", .arabic: "تغيير المنصة",
            .portuguese: "Mudar de plataforma", .swahili: "Badilisha jukwaa"
        ],
        "settings_no_platform_short": [
            .french: "Aucune", .english: "None", .arabic: "لا شيء",
            .portuguese: "Nenhuma", .swahili: "Hakuna"
        ],
        "settings_language": [
            .french: "Langue", .english: "Language", .arabic: "اللغة",
            .portuguese: "Idioma", .swahili: "Lugha"
        ],

        // MARK: - Notification locale de retour
        "notif_return_title": [
            .french: "Retourne dans ZikAfrica",
            .english: "Return to ZikAfrica",
            .arabic: "عد إلى ZikAfrica",
            .portuguese: "Volta ao ZikAfrica",
            .swahili: "Rudi ZikAfrica"
        ],
        // MARK: - Partie connectée (erreurs)
        "connected_error_create_game": [
            .french: "Impossible de créer la partie en ligne.",
            .english: "Couldn't create the online game.",
            .arabic: "تعذّر إنشاء اللعبة عبر الإنترنت.",
            .portuguese: "Não foi possível criar o jogo online.",
            .swahili: "Imeshindwa kuunda mchezo mtandaoni."
        ],
        "connected_error_remove_player": [
            .french: "Impossible de retirer ce joueur.",
            .english: "Couldn't remove this player.",
            .arabic: "تعذّر إزالة هذا اللاعب.",
            .portuguese: "Não foi possível remover este jogador.",
            .swahili: "Imeshindwa kumwondoa mchezaji huyu."
        ],
        "connected_error_sync_buzzer": [
            .french: "Impossible de synchroniser le buzzer.",
            .english: "Couldn't sync the buzzer.",
            .arabic: "تعذّر مزامنة الجرس.",
            .portuguese: "Não foi possível sincronizar o buzzer.",
            .swahili: "Imeshindwa kusawazisha buzzer."
        ],
        "connected_error_sync_players": [
            .french: "Impossible de synchroniser les joueurs.",
            .english: "Couldn't sync the players.",
            .arabic: "تعذّر مزامنة اللاعبين.",
            .portuguese: "Não foi possível sincronizar os jogadores.",
            .swahili: "Imeshindwa kusawazisha wachezaji."
        ],
        "connected_error_sync_buzz_order": [
            .french: "Impossible de synchroniser l’ordre des buzzers.",
            .english: "Couldn't sync the buzz order.",
            .arabic: "تعذّر مزامنة ترتيب الأجراس.",
            .portuguese: "Não foi possível sincronizar a ordem dos buzzers.",
            .swahili: "Imeshindwa kusawazisha mpangilio wa buzzer."
        ],
        "connected_error_firebase_auth": [
            .french: "Connexion Firebase impossible.",
            .english: "Couldn't connect to Firebase.",
            .arabic: "تعذّر الاتصال بـ Firebase.",
            .portuguese: "Não foi possível ligar ao Firebase.",
            .swahili: "Imeshindwa kuunganisha na Firebase."
        ],
        "connected_default_team_name": [
            .french: "Équipe", .english: "Team", .arabic: "فريق",
            .portuguese: "Equipa", .swahili: "Timu"
        ],
        "connected_default_player_name": [
            .french: "Joueur", .english: "Player", .arabic: "لاعب",
            .portuguese: "Jogador", .swahili: "Mchezaji"
        ],

        // MARK: - Partie connectée (écran principal)
        "connected_final_ranking": [
            .french: "CLASSEMENT FINAL", .english: "FINAL RANKING", .arabic: "الترتيب النهائي",
            .portuguese: "CLASSIFICAÇÃO FINAL", .swahili: "MATOKEO YA MWISHO"
        ],
        "connected_game_title": [
            .french: "PARTIE CONNECTÉE", .english: "CONNECTED GAME", .arabic: "اللعبة المتصلة",
            .portuguese: "JOGO CONECTADO", .swahili: "MCHEZO ULIOUNGANISHWA"
        ],
        "connected_intro": [
            .french: "Crée une salle en ligne. Les joueurs rejoignent avec leur téléphone, sans installer l’application.",
            .english: "Create an online room. Players join with their phone, no app install needed.",
            .arabic: "أنشئ غرفة عبر الإنترنت. ينضم اللاعبون بهواتفهم، دون تثبيت أي تطبيق.",
            .portuguese: "Cria uma sala online. Os jogadores entram com o telemóvel, sem instalar a app.",
            .swahili: "Unda chumba mtandaoni. Wachezaji wanajiunga kwa simu zao, bila kusakinisha programu."
        ],
        "connected_creating": [
            .french: "CRÉATION…", .english: "CREATING…", .arabic: "جارٍ الإنشاء…",
            .portuguese: "A CRIAR…", .swahili: "INAUNDWA…"
        ],
        "connected_create_button": [
            .french: "CRÉER LA PARTIE", .english: "CREATE THE GAME", .arabic: "إنشاء اللعبة",
            .portuguese: "CRIAR O JOGO", .swahili: "UNDA MCHEZO"
        ],
        "connected_scan_qr": [
            .french: "Fais scanner ce QR Code",
            .english: "Have this QR Code scanned",
            .arabic: "اطلب مسح رمز QR هذا",
            .portuguese: "Pede para digitalizarem este código QR",
            .swahili: "Waambie waskani QR Code hii"
        ],
        "connected_code_pin_format": [
            .french: "Code : %@   •   PIN : %@",
            .english: "Code: %@   •   PIN: %@",
            .arabic: "الرمز: %@   •   الرقم السري: %@",
            .portuguese: "Código: %@   •   PIN: %@",
            .swahili: "Msimbo: %@   •   PIN: %@"
        ],
        "connected_players_singular_format": [
            .french: "%d joueur connecté",
            .english: "%d player connected",
            .arabic: "لاعب واحد متصل",
            .portuguese: "%d jogador ligado",
            .swahili: "Mchezaji %d ameunganishwa"
        ],
        "connected_players_plural_format": [
            .french: "%d joueurs connectés",
            .english: "%d players connected",
            .arabic: "%d لاعبين متصلين",
            .portuguese: "%d jogadores ligados",
            .swahili: "Wachezaji %d wameunganishwa"
        ],
        "connected_waiting_players": [
            .french: "En attente des joueurs...",
            .english: "Waiting for players...",
            .arabic: "في انتظار اللاعبين...",
            .portuguese: "A aguardar jogadores...",
            .swahili: "Inasubiri wachezaji..."
        ],
        "connected_undo_last_point": [
            .french: "↶  ANNULER LE DERNIER POINT",
            .english: "↶  UNDO LAST POINT",
            .arabic: "↶  تراجع عن آخر نقطة",
            .portuguese: "↶  ANULAR O ÚLTIMO PONTO",
            .swahili: "↶  TENGUA ALAMA YA MWISHO"
        ],
        "connected_finish_game": [
            .french: "TERMINER LA PARTIE", .english: "FINISH THE GAME", .arabic: "إنهاء اللعبة",
            .portuguese: "TERMINAR O JOGO", .swahili: "MALIZA MCHEZO"
        ],

        // MARK: - Partie connectée (ligne d'équipe)
        "connected_points_suffix_format": [
            .french: "%d pts", .english: "%d pts", .arabic: "%d نقطة",
            .portuguese: "%d pts", .swahili: "pointi %d"
        ],
        "connected_remove_button": [
            .french: "RETIRER", .english: "REMOVE", .arabic: "إزالة",
            .portuguese: "REMOVER", .swahili: "ONDOA"
        ],

        // MARK: - Partie connectée (statut du buzzer)
        "connected_first_buzz_format": [
            .french: "Premier buzz : %@",
            .english: "First buzz: %@",
            .arabic: "أول ضغط: %@",
            .portuguese: "Primeiro buzz: %@",
            .swahili: "Buzz ya kwanza: %@"
        ],
        "connected_buzzer_open": [
            .french: "BUZZER OUVERT", .english: "BUZZER OPEN", .arabic: "الجرس مفتوح",
            .portuguese: "BUZZER ABERTO", .swahili: "BUZZER IMEFUNGULIWA"
        ],
        "connected_buzzer_waiting": [
            .french: "Buzzer en attente", .english: "Buzzer waiting", .arabic: "الجرس في الانتظار",
            .portuguese: "Buzzer em espera", .swahili: "Buzzer inasubiri"
        ],
        "connected_buzzer_hint_assign": [
            .french: "Attribue les points, puis relance une carte ou rejoue le son.",
            .english: "Assign the points, then scan a new card or replay the sound.",
            .arabic: "وزّع النقاط، ثم امسح بطاقة جديدة أو أعد تشغيل الصوت.",
            .portuguese: "Atribui os pontos e depois digitaliza outro cartão ou repete o som.",
            .swahili: "Gawa pointi, kisha skani kadi mpya au cheza tena sauti."
        ],
        "connected_buzzer_hint_open": [
            .french: "Les joueurs peuvent buzzer maintenant.",
            .english: "Players can buzz in now.",
            .arabic: "يمكن للاعبين الضغط على الجرس الآن.",
            .portuguese: "Os jogadores já podem carregar no buzzer.",
            .swahili: "Wachezaji wanaweza kubonyeza buzzer sasa."
        ],
        "connected_buzzer_hint_idle": [
            .french: "Le buzzer s’active automatiquement au lancement du son.",
            .english: "The buzzer activates automatically when the sound starts.",
            .arabic: "يُفعَّل الجرس تلقائيًا عند تشغيل الصوت.",
            .portuguese: "O buzzer ativa-se automaticamente quando o som começa.",
            .swahili: "Buzzer huwashwa kiotomatiki muziki unapoanza."
        ],
        "connected_buzz_order": [
            .french: "ORDRE DES BUZZERS", .english: "BUZZ ORDER", .arabic: "ترتيب الأجراس",
            .portuguese: "ORDEM DOS BUZZERS", .swahili: "MPANGILIO WA BUZZER"
        ],
        "connected_reset_buzzer": [
            .french: "RÉINITIALISER LE BUZZER", .english: "RESET THE BUZZER", .arabic: "إعادة تعيين الجرس",
            .portuguese: "REINICIAR O BUZZER", .swahili: "WEKA UPYA BUZZER"
        ]
    ]
}
