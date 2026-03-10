# frozen_string_literal: true

namespace :articles do
  desc "Add translations (EN, IT, DE, SV, NO, DA, FI) to all existing articles"
  task translate: :environment do
    translations = {}

    # Article 1
    translations["5-raisons-de-vivre-dans-la-principaute-de-monaco"] = {
      title: {
        "en" => "5 reasons to live in the Principality of Monaco",
        "it" => "5 ragioni per vivere nel Principato di Monaco",
        "de" => "5 Gründe, im Fürstentum Monaco zu leben",
        "sv" => "5 anledningar att bo i Furstendömet Monaco",
        "no" => "5 grunner til å bo i Fyrstedømmet Monaco",
        "da" => "5 grunde til at bo i Fyrstendømmet Monaco",
        "fi" => "5 syytä asua Monacon ruhtinaskunnassa"
      },
      body: {
        "en" => <<~BODY,
          With over 300 days of sunshine per year, residents of the Principality of Monaco enjoy the Mediterranean, water sports and the joys of skiing thanks to their proximity to the resorts of the Southern Alps. The advantages of living in the Principality could generate an endless list. However, we have gathered for you 5 main reasons why you should settle in Monaco.

          ### 1. An enviable geographical location and climate

          Monaco stands proudly on a narrow strip of the Mediterranean coast and is bordered by France on three sides. Its vertical urban landscape instantly distinguishes it from the foothills of the Alpes-Maritimes. On the western coast of Monaco, the cities of Nice, Cannes and Saint-Tropez are nearby. On the eastern side, past the Italian border, you will find charming towns such as Bordighera, Sanremo and Portofino.

          The climate also ranks highly on the list of advantages of living in Monaco, with approximately 300 days of sunshine per year. In July and August, temperatures average 27°C and even in January and February, the coolest months, average temperatures reach 12°C.

          ### 2. The Principality is diverse and cosmopolitan

          With nearly 120 nationalities concentrated in an area of two square kilometres, Monaco has one of the most cosmopolitan populations on the planet.

          This micro-state covers 2.02km2. Partly reclaimed from the sea, it is the second smallest independent state in the world after the Vatican. Monaco is also a true Tower of Babel. The French, Italians, British, Swiss and Belgians make up the five largest groups of foreign nationals. Foreign residents account for three-quarters of the total population of the Principality — approximately 38,000, compared to fewer than 9,000 Monegasque nationals.

          ### 3. An effective education system

          Monaco's education system follows the same curriculum as the French National Education system, with some specificities:

          - English language teaching is reinforced from nursery school to the final year of secondary school
          - French is taught as a "foreign language" to facilitate the integration of non-French-speaking students
          - The promotion of national culture is encouraged through the teaching of Monaco's history and its traditional language
          - Sports education is reinforced through compulsory physical education and swimming classes from an early age, developed sports facilities, and sports classes with adapted schedules...

          As for school infrastructure, the Principality has:

          - 9 public educational establishments: 6 nursery and primary schools, two middle schools, one general and technological high school and one vocational and hotel high school.
          - 11 nurseries: for parents of young children, the Municipality of Monaco provides 7 collective nurseries, 1 family nursery, 3 micro-nurseries and 1 early learning centre.
          - 2 private religious establishments: including the Institution François d'Assise - Nicolas Barré, a private Catholic educational establishment with classes from middle school to high school.
          - The International School of Monaco offers bilingual English-French education from nursery to high school.
          - The Académie de Danse Princesse Grace
          - Higher education courses: the International University of Monaco, a business school, the École Supérieure d'Arts Plastiques and the Institut de Formation en Soins Infirmiers.

          Education in the Principality has also entered the digital era. All teachers have been equipped with laptops since 2019, middle school students with a laptop or tablet since 2020, and high school students since 2021. The aim of this digital integration is to foster the development of students' digital skills and diversify ways of learning.

          Schooling conditions are also an essential point in the success of education in the Principality. Facilities are well-maintained and classrooms are modern. Furthermore, they have a maximum of 25 students per classroom, which promotes personalised monitoring by teachers for each student.

          All the measures taken and the government's investment in promoting an excellent education system in Monaco produce exceptional results, as pass rates for the baccalaureate and BTS exceed 95% every year.

          ### 4. A passion for sport, a Monegasque nature

          In the Principality, sport has historically always been of great importance. Thanks to frequent sporting events and state-of-the-art sports facilities, the passion for sport is omnipresent among residents.

          Monaco has gained international prestige as an important centre for all sorts of sporting events, such as the Formula 1 Grand Prix, the Monte-Carlo Rally, the Monte-Carlo Tennis Open, the Herculis, and many more.

          **What sports facilities are located in Monaco?**

          - Stadiums
            - Stade Louis II: international matches and French first league matches are hosted here. The stadium offers multidisciplinary facilities for boxing, volleyball, table tennis, squash, martial arts, basketball and many more.
          - Swimming pools
            - Centre nautique Prince Albert II: an Olympic pool, a beginners' pool and a diving pit.
            - Piscine Saint-Charles: a swimming pool located in the centre of Monte-Carlo.
            - The Stade de natation en plein air Rainier III: a pool with an Olympic basin and a diving board.
          - Other sports facilities
            - The ice rink: every winter, the Stade Nautique Rainier III transforms into a 1,000m2 ice rink.
            - The Monte-Carlo Country Club offers 23 tennis courts and hosts one of the most renowned tennis tournaments in the world.

          ### 5. Arts and culture are thriving in Monaco

          The Monegasque government actively supports the arts, cultural institutions and humanities through various programmes and events. The Fondation Prince Pierre was created to encourage the culture of letters and arts, through the creation and awarding of prizes.

          **Cultural venues of the Principality:**

          - La Compagnie des Ballets de Monte-Carlo
          - L'Orchestre Philharmonique de Monte-Carlo
          - L'Opéra de Monte-Carlo
          - Le Théâtre Princesse Grace
          - Le Printemps des Arts

          **Museums of the Principality:**

          - Le Musée océanographique de Monaco
          - Le Musée d'Anthropologie Préhistorique
          - Le Musée des Timbres et des Monnaies
          - Le Nouveau Musée National de Monaco (N.M.N.M.)
          - Le Musée de la collection de voitures anciennes du Prince Rainier III
          - Le Musée Naval
          - Various exhibitions at the Grimaldi Forum

          Good to know:

          One of the most attractive advantages of living in Monaco is the fact that residents are exempt from income tax. If you want to learn more about its possible impact on your private and professional life, read our article on the unique advantages of Monaco's tax system.

          In conclusion, Monaco's excellent reputation attracts investors from around the world, which makes its economy and its residents prosper. As a result, living conditions in Monaco are unmatched, and poverty is non-existent in the state. Political stability, low unemployment and crime rates, high-quality healthcare and government aid programmes help maintain Monaco's high standard of living.

          If you are planning to settle there, here is an article on everything you need to know about buying real estate in Monaco.
        BODY
        "it" => <<~BODY,
          Con oltre 300 giorni di sole all'anno, gli abitanti del Principato di Monaco godono del Mediterraneo, degli sport acquatici e delle gioie dello sci grazie alla vicinanza alle stazioni delle Alpi del Sud. I vantaggi di vivere nel Principato potrebbero generare una lista infinita. Tuttavia, abbiamo raccolto per voi 5 ragioni principali per cui dovreste trasferirvi a Monaco.

          ### 1. Una posizione geografica e un clima invidiabili

          Monaco si erge fieramente su una stretta striscia della costa mediterranea ed è delimitata dalla Francia su tre lati. Il suo paesaggio urbano verticale la distingue immediatamente dai contrafforti delle Alpi Marittime. Sulla costa occidentale di Monaco, le città di Nizza, Cannes e Saint-Tropez sono nelle vicinanze. Sul lato orientale, oltre il confine italiano, troverete affascinanti città come Bordighera, Sanremo e Portofino.

          Il clima occupa un posto di rilievo nella lista dei vantaggi della vita a Monaco, con circa 300 giorni di sole all'anno. In luglio e agosto, le temperature raggiungono in media 27°C e anche in gennaio e febbraio, i mesi più freschi, le temperature medie raggiungono i 12°C.

          ### 2. Il Principato è diversificato e cosmopolita

          Con quasi 120 nazionalità concentrate su una superficie di due chilometri quadrati, Monaco possiede una delle popolazioni più cosmopolite del pianeta.

          Questo micro-Stato occupa 2,02km2. In parte strappato al mare, è il secondo Stato indipendente più piccolo del mondo dopo il Vaticano. Monaco è anche una vera Torre di Babele. Francesi, italiani, britannici, svizzeri e belgi costituiscono i cinque maggiori gruppi di cittadini stranieri. I residenti stranieri rappresentano tre quarti della popolazione totale del Principato — circa 38.000, contro meno di 9.000 cittadini monegaschi.

          ### 3. Un sistema educativo efficace

          Il sistema educativo di Monaco segue lo stesso programma dell'Educazione Nazionale francese con alcune specificità:

          - l'insegnamento della lingua inglese è rafforzato dalla scuola materna all'ultimo anno delle superiori
          - il francese è insegnato come "lingua straniera" per facilitare l'integrazione degli alunni non francofoni
          - la promozione della cultura nazionale è favorita dall'insegnamento della storia di Monaco e della sua lingua tradizionale
          - l'insegnamento dello sport è rafforzato grazie ai corsi obbligatori di educazione fisica e nuoto fin dalla più tenera età, alle strutture sportive sviluppate, alle classi sportive con orari adattati...

          Per quanto riguarda le infrastrutture scolastiche, il Principato conta:

          - 9 istituti scolastici pubblici: 6 scuole materne ed elementari, due scuole medie, un liceo di insegnamento generale e tecnologico e un liceo professionale e alberghiero.
          - 11 asili nido: per i genitori di bambini piccoli, il Comune di Monaco mette a disposizione 7 asili collettivi, 1 asilo familiare, 3 micro-asili e 1 giardino d'infanzia.
          - 2 istituti confessionali privati: tra cui l'Institution François d'Assise - Nicolas Barré, un istituto di insegnamento privato cattolico con classi dalle medie al liceo.
          - L'International School of Monaco propone un insegnamento bilingue inglese-francese dalla materna al liceo.
          - L'Académie de Danse Princesse Grace
          - Formazioni di istruzione superiore: l'International University of Monaco, una scuola di commercio, l'École Supérieure d'Arts Plastiques e l'Institut de Formation en Soins Infirmiers.

          L'educazione nel Principato è entrata anche nell'era digitale. Tutti gli insegnanti sono dotati di computer portatili dal 2019, gli studenti delle medie di un portatile o tablet dal 2020 e i liceali dal 2021. L'obiettivo di questa integrazione digitale è favorire lo sviluppo delle competenze digitali degli alunni e diversificare i modi di apprendere.

          Le condizioni di scolarizzazione sono anche un punto essenziale per il successo dell'educazione nel Principato. Le strutture sono ben mantenute e le aule sono moderne. Inoltre, contano un massimo di 25 alunni per aula, il che favorisce un monitoraggio personalizzato da parte degli insegnanti per ogni alunno.

          L'insieme delle misure adottate e l'investimento del governo per favorire un eccellente sistema educativo a Monaco danno risultati eccezionali, poiché i tassi di superamento del baccalaureato e del BTS superano ogni anno il 95%.

          ### 4. La passione per lo sport, una natura monegasca

          Nel Principato, lo sport ha storicamente sempre avuto grande importanza. Grazie a frequenti manifestazioni sportive e strutture sportive all'avanguardia, la passione per lo sport è onnipresente tra i residenti.

          Monaco ha acquisito un prestigio internazionale come centro importante per ogni tipo di evento sportivo, come il Gran Premio di Formula 1, il Rally di Monte-Carlo, l'Open di tennis di Monte-Carlo, l'Herculis, e molti altri ancora.

          **Quali strutture sportive si trovano a Monaco?**

          - Stadi
            - Stade Louis II: vi si svolgono partite internazionali e partite della prima lega francese. Lo stadio offre strutture multidisciplinari per la pratica di pugilato, pallavolo, tennis da tavolo, squash, arti marziali, basket e molti altri sport.
          - Piscine
            - Centre nautique Prince Albert II: una vasca olimpionica, una vasca per principianti e una fossa per le immersioni.
            - Piscine Saint-Charles: una piscina situata nel centro di Monte-Carlo.
            - Lo Stade de natation en plein air Rainier III: una piscina con vasca olimpionica e trampolino.
          - Altre strutture sportive
            - La pista di pattinaggio: ogni inverno, lo Stade Nautique Rainier III si trasforma in una pista di pattinaggio di 1.000m2.
            - Il Monte-Carlo Country Club offre 23 campi da tennis e ospita uno dei tornei di tennis più rinomati al mondo.

          ### 5. Le arti e la cultura sono in pieno sviluppo a Monaco

          Il governo monegasco sostiene attivamente le arti, le istituzioni culturali e le scienze umane attraverso diversi programmi e eventi. La Fondation Prince Pierre è stata creata per incoraggiare la cultura delle lettere e delle arti, attraverso la creazione e l'assegnazione di premi.

          **I luoghi culturali del Principato:**

          - La Compagnie des Ballets de Monte-Carlo
          - L'Orchestre Philharmonique de Monte-Carlo
          - L'Opéra de Monte-Carlo
          - Le Théâtre Princesse Grace
          - Le Printemps des Arts

          **I musei del Principato:**

          - Le Musée océanographique de Monaco
          - Le Musée d'Anthropologie Préhistorique
          - Le Musée des Timbres et des Monnaies
          - Le Nouveau Musée National de Monaco (N.M.N.M.)
          - Le Musée de la collection de voitures anciennes du Prince Rainier III
          - Le Musée Naval
          - Diverse esposizioni al Grimaldi Forum

          Da sapere:

          Uno dei vantaggi più attraenti della vita a Monaco è il fatto che i residenti sono esenti dall'imposta sul reddito. Se volete saperne di più sul suo possibile impatto sulla vostra vita privata e professionale, leggete il nostro articolo sui vantaggi unici del sistema fiscale di Monaco.

          In conclusione, l'eccellente reputazione di Monaco attira investitori da tutto il mondo, facendo prosperare la sua economia e i suoi residenti. Di conseguenza, le condizioni di vita a Monaco sono ineguagliabili e la povertà è inesistente nello Stato. La stabilità politica, i bassi tassi di disoccupazione e criminalità, l'assistenza sanitaria di alta qualità e i programmi di aiuto governativo permettono il mantenimento dell'alto tenore di vita a Monaco.

          Se avete in progetto di trasferirvi, ecco un articolo su tutto ciò che dovete sapere sull'acquisto di immobili a Monaco.
        BODY
        "de" => <<~BODY,
          Mit über 300 Sonnentagen pro Jahr genießen die Einwohner des Fürstentums Monaco das Mittelmeer, Wassersportarten und die Freuden des Skifahrens dank der Nähe zu den Skigebieten der Südalpen. Die Vorteile des Lebens im Fürstentum könnten eine endlose Liste ergeben. Dennoch haben wir für Sie 5 Hauptgründe zusammengestellt, warum Sie sich in Monaco niederlassen sollten.

          ### 1. Eine beneidenswerte geographische Lage und ein beneidenswertes Klima

          Monaco erhebt sich stolz auf einem schmalen Streifen der Mittelmeerküste und wird auf drei Seiten von Frankreich begrenzt. Seine vertikale Stadtlandschaft unterscheidet es sofort von den Ausläufern der Alpes-Maritimes. An der Westküste Monacos befinden sich die Städte Nizza, Cannes und Saint-Tropez in der Nähe. Auf der Ostseite, hinter der italienischen Grenze, finden Sie charmante Städte wie Bordighera, Sanremo und Portofino.

          Das Klima steht ebenfalls weit oben auf der Liste der Vorteile des Lebens in Monaco, mit etwa 300 Sonnentagen pro Jahr. Im Juli und August erreichen die Temperaturen durchschnittlich 27°C, und selbst im Januar und Februar, den kühlsten Monaten, liegen die Durchschnittstemperaturen bei 12°C.

          ### 2. Das Fürstentum ist vielfältig und kosmopolitisch

          Mit fast 120 Nationalitäten auf einer Fläche von zwei Quadratkilometern hat Monaco eine der kosmopolitischsten Bevölkerungen der Welt.

          Dieser Mikrostaat erstreckt sich über 2,02km2. Teilweise dem Meer abgewonnen, ist er nach dem Vatikan der zweitkleinste unabhängige Staat der Welt. Monaco ist auch ein wahrer Turm zu Babel. Franzosen, Italiener, Briten, Schweizer und Belgier bilden die fünf größten Gruppen ausländischer Staatsangehöriger. Ausländische Einwohner machen drei Viertel der Gesamtbevölkerung des Fürstentums aus — etwa 38.000, gegenüber weniger als 9.000 monegassischen Staatsangehörigen.

          ### 3. Ein effektives Bildungssystem

          Monacos Bildungssystem folgt dem gleichen Lehrplan wie das französische nationale Bildungssystem mit einigen Besonderheiten:

          - Der Englischunterricht wird vom Kindergarten bis zum Abitur verstärkt
          - Französisch wird als "Fremdsprache" unterrichtet, um die Integration nicht-frankophoner Schüler zu erleichtern
          - Die Förderung der nationalen Kultur wird durch den Unterricht der Geschichte Monacos und seiner traditionellen Sprache begünstigt
          - Der Sportunterricht wird durch obligatorischen Sport- und Schwimmunterricht ab dem frühesten Alter, ausgebaute Sportanlagen und Sportklassen mit angepassten Stundenplänen verstärkt...

          Was die schulische Infrastruktur betrifft, verfügt das Fürstentum über:

          - 9 öffentliche Bildungseinrichtungen: 6 Kindergärten und Grundschulen, zwei Mittelschulen, ein allgemeinbildendes und technologisches Gymnasium und ein berufsbildendes und Hotelgymnasium.
          - 11 Kinderkrippen: Für Eltern von Kleinkindern stellt die Gemeinde Monaco 7 Gemeinschaftskrippen, 1 Familienkrippe, 3 Minikrippen und 1 Frühförderungsgarten zur Verfügung.
          - 2 private konfessionelle Einrichtungen: darunter die Institution François d'Assise - Nicolas Barré, eine private katholische Bildungseinrichtung mit Klassen von der Mittelschule bis zum Gymnasium.
          - Die International School of Monaco bietet zweisprachigen Englisch-Französisch-Unterricht vom Kindergarten bis zum Gymnasium.
          - Die Académie de Danse Princesse Grace
          - Hochschulausbildungen: die International University of Monaco, eine Wirtschaftsschule, die École Supérieure d'Arts Plastiques und das Institut de Formation en Soins Infirmiers.

          Die Bildung im Fürstentum ist auch in das digitale Zeitalter eingetreten. Alle Lehrer sind seit 2019 mit Laptops ausgestattet, Mittelschüler seit 2020 mit einem Laptop oder Tablet und Gymnasiasten seit 2021. Ziel dieser digitalen Integration ist es, die Entwicklung digitaler Kompetenzen der Schüler zu fördern und die Lernmethoden zu diversifizieren.

          Die Schulbedingungen sind ebenfalls ein wesentlicher Punkt für den Bildungserfolg im Fürstentum. Die Einrichtungen sind gepflegt und die Klassenzimmer sind modern. Außerdem haben sie maximal 25 Schüler pro Klasse, was eine persönliche Betreuung durch die Lehrer für jeden Schüler fördert.

          Alle getroffenen Maßnahmen und die Investitionen der Regierung zur Förderung eines ausgezeichneten Bildungssystems in Monaco liefern hervorragende Ergebnisse, da die Erfolgsquoten beim Abitur und BTS jedes Jahr 95% übersteigen.

          ### 4. Die Leidenschaft für Sport, eine monegassische Eigenschaft

          Im Fürstentum hat der Sport historisch immer eine große Bedeutung gehabt. Dank häufiger Sportveranstaltungen und modernster Sporteinrichtungen ist die Begeisterung für Sport bei den Einwohnern allgegenwärtig.

          Monaco hat internationales Prestige als wichtiges Zentrum für alle Arten von Sportveranstaltungen erlangt, wie den Formel-1-Grand-Prix, die Rallye Monte-Carlo, die Monte-Carlo Tennis Open, Herculis und viele weitere.

          **Welche Sportanlagen befinden sich in Monaco?**

          - Stadien
            - Stade Louis II: Hier finden internationale Spiele und Spiele der französischen ersten Liga statt. Das Stadion bietet multidisziplinäre Einrichtungen für Boxen, Volleyball, Tischtennis, Squash, Kampfkünste, Basketball und vieles mehr.
          - Schwimmbäder
            - Centre nautique Prince Albert II: ein olympisches Becken, ein Anfängerbecken und eine Tauchgrube.
            - Piscine Saint-Charles: ein Schwimmbad im Zentrum von Monte-Carlo.
            - Das Stade de natation en plein air Rainier III: ein Schwimmbad mit olympischem Becken und Sprungturm.
          - Weitere Sportanlagen
            - Die Eisbahn: Jeden Winter verwandelt sich das Stade Nautique Rainier III in eine 1.000m2 große Eisbahn.
            - Der Monte-Carlo Country Club bietet 23 Tennisplätze und beherbergt eines der renommiertesten Tennisturniere der Welt.

          ### 5. Kunst und Kultur blühen in Monaco

          Die monegassische Regierung unterstützt aktiv die Künste, kulturelle Institutionen und Geisteswissenschaften durch verschiedene Programme und Veranstaltungen. Die Fondation Prince Pierre wurde gegründet, um die Kultur der Literatur und Künste durch die Schaffung und Vergabe von Preisen zu fördern.

          **Kulturelle Einrichtungen des Fürstentums:**

          - La Compagnie des Ballets de Monte-Carlo
          - L'Orchestre Philharmonique de Monte-Carlo
          - L'Opéra de Monte-Carlo
          - Le Théâtre Princesse Grace
          - Le Printemps des Arts

          **Museen des Fürstentums:**

          - Le Musée océanographique de Monaco
          - Le Musée d'Anthropologie Préhistorique
          - Le Musée des Timbres et des Monnaies
          - Le Nouveau Musée National de Monaco (N.M.N.M.)
          - Le Musée de la collection de voitures anciennes du Prince Rainier III
          - Le Musée Naval
          - Verschiedene Ausstellungen im Grimaldi Forum

          Gut zu wissen:

          Einer der attraktivsten Vorteile des Lebens in Monaco ist die Tatsache, dass die Einwohner von der Einkommensteuer befreit sind. Wenn Sie mehr über die möglichen Auswirkungen auf Ihr Privat- und Berufsleben erfahren möchten, lesen Sie unseren Artikel über die einzigartigen Vorteile des monegassischen Steuersystems.

          Zusammenfassend zieht Monacos ausgezeichneter Ruf Investoren aus der ganzen Welt an, was seine Wirtschaft und seine Einwohner gedeihen lässt. Folglich sind die Lebensbedingungen in Monaco unübertroffen, und Armut existiert im Staat nicht. Politische Stabilität, niedrige Arbeitslosigkeit und Kriminalitätsraten, hochwertige Gesundheitsversorgung und staatliche Hilfsprogramme ermöglichen die Aufrechterhaltung des hohen Lebensstandards in Monaco.

          Wenn Sie planen, sich dort niederzulassen, finden Sie hier einen Artikel über alles, was Sie über den Kauf von Immobilien in Monaco wissen müssen.
        BODY
        "sv" => <<~BODY,
          Med över 300 soldagar per år njuter invånarna i Furstendömet Monaco av Medelhavet, vattensporter och skidåkningens glädje tack vare närheten till skidorterna i Sydalperna. Fördelarna med att bo i Furstendömet kan generera en oändlig lista. Vi har dock sammanställt 5 huvudsakliga skäl för varför du bör bosätta dig i Monaco.

          ### 1. Ett avundsvärt geografiskt läge och klimat

          Monaco reser sig stolt på en smal remsa av Medelhavskusten och gränsar till Frankrike på tre sidor. Dess vertikala stadslandskap skiljer det omedelbart från Alpes-Maritimes utlöpare. På Monacos västkust ligger städerna Nice, Cannes och Saint-Tropez i närheten. På östsidan, bortom den italienska gränsen, finner du charmiga städer som Bordighera, Sanremo och Portofino.

          Klimatet rankas också högt på listan över fördelar med att bo i Monaco, med cirka 300 soldagar per år. I juli och augusti når temperaturerna i genomsnitt 27°C och även i januari och februari, de svalaste månaderna, når medeltemperaturerna 12°C.

          ### 2. Furstendömet är mångsidigt och kosmopolitiskt

          Med nästan 120 nationaliteter koncentrerade på en yta av två kvadratkilometer har Monaco en av de mest kosmopolitiska befolkningarna på planeten.

          Denna mikrostat täcker 2,02km2. Delvis landvunnen från havet är den världens näst minsta oberoende stat efter Vatikanen. Monaco är också ett verkligt Babels torn. Fransmän, italienare, britter, schweizare och belgare utgör de fem största grupperna av utländska medborgare. Utländska invånare utgör tre fjärdedelar av Furstendömets totala befolkning — cirka 38 000, jämfört med färre än 9 000 monegaskiska medborgare.

          ### 3. Ett effektivt utbildningssystem

          Monacos utbildningssystem följer samma läroplan som det franska nationella utbildningssystemet med vissa särskiljande drag:

          - Engelskundervisningen förstärks från förskolan till gymnasiets sista år
          - Franska undervisas som "främmande språk" för att underlätta integrationen av icke-fransktalande elever
          - Främjandet av den nationella kulturen gynnas genom undervisning i Monacos historia och dess traditionella språk
          - Idrottsundervisningen förstärks genom obligatorisk fysisk utbildning och simundervisning från tidig ålder, utvecklade idrottsanläggningar och sportklasser med anpassade scheman...

          Vad gäller skolinfrastrukturen har Furstendömet:

          - 9 offentliga utbildningsinstitutioner: 6 förskolor och grundskolor, två mellanstadieskolor, ett allmänt och teknologiskt gymnasium och ett yrkes- och hotellgymnasium.
          - 11 förskolor: för föräldrar till små barn tillhandahåller Monacos kommun 7 kollektiva förskolor, 1 familjeförskola, 3 mikroförskolor och 1 tidig inlärningscenter.
          - 2 privata konfessionella institutioner: däribland Institution François d'Assise - Nicolas Barré, en privat katolsk utbildningsinstitution med klasser från mellanstadiet till gymnasiet.
          - International School of Monaco erbjuder tvåspråkig engelsk-fransk utbildning från förskolan till gymnasiet.
          - Académie de Danse Princesse Grace
          - Högre utbildningar: International University of Monaco, en handelshögskola, École Supérieure d'Arts Plastiques och Institut de Formation en Soins Infirmiers.

          Utbildningen i Furstendömet har också gått in i den digitala eran. Alla lärare har utrustats med bärbara datorer sedan 2019, mellanstadieelever med en bärbar dator eller surfplatta sedan 2020 och gymnasieelever sedan 2021. Målet med denna digitala integration är att främja utvecklingen av elevernas digitala kompetenser och diversifiera inlärningssätten.

          Skolförhållandena är också en väsentlig punkt för utbildningens framgång i Furstendömet. Anläggningarna är välskötta och klassrummen är moderna. Dessutom har de högst 25 elever per klassrum, vilket främjar personlig uppföljning av lärarna för varje elev.

          Alla vidtagna åtgärder och regeringens investering i att främja ett utmärkt utbildningssystem i Monaco ger exceptionella resultat, eftersom godkännandefrekvenserna för studenten och BTS överstiger 95% varje år.

          ### 4. Passionen för sport, en monegaskisk egenskap

          I Furstendömet har idrott historiskt alltid haft stor betydelse. Tack vare frekventa sportevenemang och toppmoderna sportanläggningar är passionen för sport allestädes närvarande bland invånarna.

          Monaco har fått internationellt anseende som ett viktigt centrum för alla typer av sportevenemang, såsom Formel 1-Grand Prix, Rallyt Monte-Carlo, Monte-Carlo Tennis Open, Herculis och många fler.

          **Vilka sportanläggningar finns i Monaco?**

          - Stadion
            - Stade Louis II: internationella matcher och matcher i den franska första ligan arrangeras här. Stadion erbjuder multidisciplinära anläggningar för boxning, volleyboll, bordtennis, squash, kampsport, basket och mycket mer.
          - Simbassänger
            - Centre nautique Prince Albert II: en olympisk bassäng, en nybörjarbassäng och en dykgrop.
            - Piscine Saint-Charles: en simbassäng belägen i centrum av Monte-Carlo.
            - Stade de natation en plein air Rainier III: en pool med olympisk bassäng och hopptorn.
          - Övriga sportanläggningar
            - Isrinken: varje vinter förvandlas Stade Nautique Rainier III till en 1 000m2 stor isrink.
            - Monte-Carlo Country Club erbjuder 23 tennisbanor och är värd för en av de mest ansedda tennisturneringarna i världen.

          ### 5. Konst och kultur blomstrar i Monaco

          Monacos regering stöder aktivt konst, kulturinstitutioner och humaniora genom olika program och evenemang. Fondation Prince Pierre skapades för att uppmuntra litteratur- och konstkulturen genom att skapa och dela ut priser.

          **Kulturella platser i Furstendömet:**

          - La Compagnie des Ballets de Monte-Carlo
          - L'Orchestre Philharmonique de Monte-Carlo
          - L'Opéra de Monte-Carlo
          - Le Théâtre Princesse Grace
          - Le Printemps des Arts

          **Museer i Furstendömet:**

          - Le Musée océanographique de Monaco
          - Le Musée d'Anthropologie Préhistorique
          - Le Musée des Timbres et des Monnaies
          - Le Nouveau Musée National de Monaco (N.M.N.M.)
          - Le Musée de la collection de voitures anciennes du Prince Rainier III
          - Le Musée Naval
          - Olika utställningar på Grimaldi Forum

          Bra att veta:

          En av de mest attraktiva fördelarna med att bo i Monaco är att invånarna är befriade från inkomstskatt. Om du vill veta mer om dess möjliga inverkan på ditt privat- och yrkesliv, läs vår artikel om de unika fördelarna med Monacos skattesystem.

          Sammanfattningsvis attraherar Monacos utmärkta rykte investerare från hela världen, vilket får dess ekonomi och invånare att blomstra. Som ett resultat är levnadsvillkoren i Monaco oöverträffade och fattigdom är obefintlig i staten. Politisk stabilitet, låg arbetslöshet och brottslighet, högkvalitativ sjukvård och statliga hjälpprogram upprätthåller den höga levnadsstandarden i Monaco.

          Om du planerar att bosätta dig där, här är en artikel om allt du behöver veta om att köpa fastigheter i Monaco.
        BODY
        "no" => <<~BODY,
          Med over 300 soldager i året nyter innbyggerne i Fyrstedømmet Monaco godt av Middelhavet, vannsport og skiglede takket være nærheten til skistedene i Søralpene. Fordelene ved å bo i Fyrstedømmet kan generere en uendelig liste. Vi har likevel samlet 5 hovedgrunner til at du bør bosette deg i Monaco.

          ### 1. En misunnelsesverdig geografisk beliggenhet og klima

          Monaco reiser seg stolt på en smal stripe av Middelhavskysten og grenser til Frankrike på tre sider. Det vertikale bylandskapet skiller det umiddelbart fra Alpes-Maritimes' utløpere. På vestkysten av Monaco ligger byene Nice, Cannes og Saint-Tropez i nærheten. På østsiden, forbi den italienske grensen, finner du sjarmerende byer som Bordighera, Sanremo og Portofino.

          Klimaet rangerer også høyt på listen over fordeler ved å bo i Monaco, med omtrent 300 soldager i året. I juli og august når temperaturene i gjennomsnitt 27°C, og selv i januar og februar, de kjøligste månedene, når gjennomsnittstemperaturene 12°C.

          ### 2. Fyrstedømmet er mangfoldig og kosmopolitisk

          Med nesten 120 nasjonaliteter konsentrert på et areal på to kvadratkilometer har Monaco en av de mest kosmopolitiske befolkningene på planeten.

          Denne mikrostaten dekker 2,02km2. Delvis vunnet fra havet er den verdens nest minste uavhengige stat etter Vatikanstaten. Monaco er også et ekte Babels tårn. Franskmenn, italienere, briter, sveitsere og belgiere utgjør de fem største gruppene av utenlandske statsborgere. Utenlandske innbyggere utgjør tre fjerdedeler av Fyrstedømmets totale befolkning — omtrent 38 000, mot færre enn 9 000 monegaskiske statsborgere.

          ### 3. Et effektivt utdanningssystem

          Monacos utdanningssystem følger det samme pensumet som det franske nasjonale utdanningssystemet med noen spesifikke trekk:

          - Engelskundervisningen er forsterket fra barnehagen til siste år på videregående
          - Fransk undervises som "fremmedspråk" for å lette integreringen av ikke-fransktalende elever
          - Fremming av nasjonal kultur ivaretas gjennom undervisning i Monacos historie og dets tradisjonelle språk
          - Idrettsundervisningen er forsterket gjennom obligatorisk kroppsøving og svømmeundervisning fra tidlig alder, utviklede idrettsanlegg og idrettsklasser med tilpassede timeplaner...

          Når det gjelder skoleinfrastruktur, har Fyrstedømmet:

          - 9 offentlige utdanningsinstitusjoner: 6 barnehager og barneskoler, to ungdomsskoler, en allmennfaglig og teknologisk videregående skole og en yrkesfaglig og hotellvideregående skole.
          - 11 barnehager: for foreldre med småbarn stiller Monaco kommune til rådighet 7 fellesbarnehager, 1 familiebarnehage, 3 mikrobarnehager og 1 tidlig læringssenter.
          - 2 private konfesjonelle institusjoner: deriblant Institution François d'Assise - Nicolas Barré, en privat katolsk utdanningsinstitusjon med klasser fra ungdomsskolen til videregående.
          - International School of Monaco tilbyr tospråklig engelsk-fransk undervisning fra barnehagen til videregående.
          - Académie de Danse Princesse Grace
          - Høyere utdanning: International University of Monaco, en handelshøyskole, École Supérieure d'Arts Plastiques og Institut de Formation en Soins Infirmiers.

          Utdanningen i Fyrstedømmet har også gått inn i den digitale tidsalderen. Alle lærere har vært utstyrt med bærbare datamaskiner siden 2019, ungdomsskoleelever med en bærbar datamaskin eller nettbrett siden 2020 og videregåendeelever siden 2021. Målet med denne digitale integrasjonen er å fremme utviklingen av elevenes digitale ferdigheter og diversifisere læringsmetodene.

          Skoleforholdene er også et vesentlig punkt for utdanningens suksess i Fyrstedømmet. Anleggene er godt vedlikeholdt og klasserommene er moderne. Dessuten har de maksimalt 25 elever per klasserom, noe som fremmer personlig oppfølging fra lærerne for hver elev.

          Alle tiltakene og regjeringens investering i å fremme et utmerket utdanningssystem i Monaco gir eksepsjonelle resultater, ettersom beståttraten for baccalauréat og BTS overstiger 95% hvert år.

          ### 4. Lidenskapen for sport, en monegaskisk egenskap

          I Fyrstedømmet har idrett historisk alltid hatt stor betydning. Takket være hyppige sportsarrangementer og toppmoderne idrettsanlegg er lidenskapen for sport allestedsnærværende blant innbyggerne.

          Monaco har oppnådd internasjonalt prestisje som et viktig senter for alle typer sportsbegivenheter, som Formel 1 Grand Prix, Rally Monte-Carlo, Monte-Carlo Tennis Open, Herculis og mange flere.

          **Hvilke idrettsanlegg finnes i Monaco?**

          - Stadioner
            - Stade Louis II: internasjonale kamper og kamper i den franske førstedivisjonen arrangeres her. Stadionet tilbyr tverrfaglige fasiliteter for boksing, volleyball, bordtennis, squash, kampsport, basketball og mye mer.
          - Svømmebassenger
            - Centre nautique Prince Albert II: et olympisk basseng, et nybegynnerbasseng og en dykkegrop.
            - Piscine Saint-Charles: et svømmebasseng i sentrum av Monte-Carlo.
            - Stade de natation en plein air Rainier III: et svømmeanlegg med olympisk basseng og stupebrett.
          - Andre idrettsanlegg
            - Skøytebanen: hver vinter forvandles Stade Nautique Rainier III til en 1 000m2 stor skøytebane.
            - Monte-Carlo Country Club tilbyr 23 tennisbaner og er vertskap for en av verdens mest anerkjente tennisturneringer.

          ### 5. Kunst og kultur blomstrer i Monaco

          Den monegaskiske regjeringen støtter aktivt kunst, kulturinstitusjoner og humaniora gjennom ulike programmer og arrangementer. Fondation Prince Pierre ble opprettet for å fremme litteratur- og kunstkulturen gjennom opprettelse og tildeling av priser.

          **Kultursteder i Fyrstedømmet:**

          - La Compagnie des Ballets de Monte-Carlo
          - L'Orchestre Philharmonique de Monte-Carlo
          - L'Opéra de Monte-Carlo
          - Le Théâtre Princesse Grace
          - Le Printemps des Arts

          **Museer i Fyrstedømmet:**

          - Le Musée océanographique de Monaco
          - Le Musée d'Anthropologie Préhistorique
          - Le Musée des Timbres et des Monnaies
          - Le Nouveau Musée National de Monaco (N.M.N.M.)
          - Le Musée de la collection de voitures anciennes du Prince Rainier III
          - Le Musée Naval
          - Diverse utstillinger på Grimaldi Forum

          Godt å vite:

          En av de mest attraktive fordelene ved å bo i Monaco er at innbyggerne er fritatt for inntektsskatt. Hvis du vil vite mer om den mulige innvirkningen på ditt privat- og yrkesliv, les vår artikkel om de unike fordelene ved Monacos skattesystem.

          Avslutningsvis tiltrekker Monacos utmerkede omdømme investorer fra hele verden, noe som får økonomien og innbyggerne til å blomstre. Som et resultat er levekårene i Monaco uovertrufne, og fattigdom er ikke-eksisterende i staten. Politisk stabilitet, lav arbeidsledighet og kriminalitet, helsetjenester av høy kvalitet og statlige hjelpeprogrammer opprettholder den høye levestandarden i Monaco.

          Hvis du planlegger å bosette deg der, her er en artikkel om alt du trenger å vite om å kjøpe eiendom i Monaco.
        BODY
        "da" => <<~BODY,
          Med over 300 solskinsdage om året nyder beboerne i Fyrstendømmet Monaco godt af Middelhavet, vandsport og skiglæder takket være nærheden til skistederne i Sydalperne. Fordelene ved at bo i Fyrstendømmet kan generere en uendelig liste. Vi har dog samlet 5 hovedgrunde til, at du bør bosætte dig i Monaco.

          ### 1. En misundelsesværdig geografisk beliggenhed og klima

          Monaco rejser sig stolt på en smal stribe af Middelhavskysten og grænser op til Frankrig på tre sider. Dets vertikale bylandskab adskiller det øjeblikkeligt fra Alpes-Maritimes' udløbere. På Monacos vestkyst ligger byerne Nice, Cannes og Saint-Tropez i nærheden. På østsiden, forbi den italienske grænse, finder du charmerende byer som Bordighera, Sanremo og Portofino.

          Klimaet rangerer også højt på listen over fordele ved at bo i Monaco med cirka 300 solskinsdage om året. I juli og august når temperaturerne i gennemsnit 27°C, og selv i januar og februar, de køligste måneder, når gennemsnitstemperaturerne 12°C.

          ### 2. Fyrstendømmet er mangfoldigt og kosmopolitisk

          Med næsten 120 nationaliteter koncentreret på et areal på to kvadratkilometer har Monaco en af de mest kosmopolitiske befolkninger på planeten.

          Denne mikrostat dækker 2,02km2. Delvis indvundet fra havet er det verdens næstmindste uafhængige stat efter Vatikanstaten. Monaco er også et sandt Babelstårn. Franskmænd, italienere, briter, schweizere og belgiere udgør de fem største grupper af udenlandske statsborgere. Udenlandske beboere udgør tre fjerdedele af Fyrstendømmets samlede befolkning — cirka 38.000, mod færre end 9.000 monegaskiske statsborgere.

          ### 3. Et effektivt uddannelsessystem

          Monacos uddannelsessystem følger det samme pensum som det franske nationale uddannelsessystem med visse særlige træk:

          - Engelskundervisningen er forstærket fra børnehaven til det sidste gymnasieår
          - Fransk undervises som "fremmedsprog" for at lette integrationen af ikke-fransktalende elever
          - Fremme af den nationale kultur ivarretages gennem undervisning i Monacos historie og dets traditionelle sprog
          - Idrætsundervisningen er forstærket gennem obligatorisk idræt og svømmeundervisning fra en tidlig alder, udviklede sportsfaciliteter og sportsklasser med tilpassede skemaer...

          Hvad angår skoleinfrastrukturen, har Fyrstendømmet:

          - 9 offentlige uddannelsesinstitutioner: 6 børnehaver og grundskoler, to ungdomsskoler, et alment og teknologisk gymnasium og et erhvervs- og hotelgymnasium.
          - 11 vuggestuer: for forældre til småbørn stiller Monaco kommune 7 fællesvuggestuer, 1 familievuggestue, 3 mikrovuggestuer og 1 tidligt læringscenter til rådighed.
          - 2 private konfessionelle institutioner: herunder Institution François d'Assise - Nicolas Barré, en privat katolsk uddannelsesinstitution med klasser fra ungdomsskolen til gymnasiet.
          - International School of Monaco tilbyder tosproget engelsk-fransk undervisning fra børnehaven til gymnasiet.
          - Académie de Danse Princesse Grace
          - Videregående uddannelser: International University of Monaco, en handelsskole, École Supérieure d'Arts Plastiques og Institut de Formation en Soins Infirmiers.

          Uddannelsen i Fyrstendømmet er også trådt ind i den digitale æra. Alle lærere har været udstyret med bærbare computere siden 2019, ungdomsskoleelever med en bærbar computer eller tablet siden 2020 og gymnasieelever siden 2021. Målet med denne digitale integration er at fremme udviklingen af elevernes digitale kompetencer og diversificere læringsmetoderne.

          Skoleforholdene er også et væsentligt punkt for uddannelsens succes i Fyrstendømmet. Faciliteterne er velvedligeholdte, og klasselokalerne er moderne. Desuden har de maksimalt 25 elever per klasselokale, hvilket fremmer personlig opfølgning fra lærerne for hver elev.

          Alle de trufne foranstaltninger og regeringens investering i at fremme et fremragende uddannelsessystem i Monaco giver exceptionelle resultater, da beståelsesprocenterne for baccalauréat og BTS hvert år overstiger 95%.

          ### 4. Passionen for sport, en monegaskisk egenskab

          I Fyrstendømmet har sport historisk altid haft stor betydning. Takket være hyppige sportsbegivenheder og topmoderne sportsfaciliteter er passionen for sport allestedsnærværende blandt beboerne.

          Monaco har opnået internationalt prestige som et vigtigt center for alle former for sportsbegivenheder, såsom Formel 1 Grand Prix, Rally Monte-Carlo, Monte-Carlo Tennis Open, Herculis og mange flere.

          **Hvilke sportsfaciliteter findes i Monaco?**

          - Stadioner
            - Stade Louis II: internationale kampe og kampe i den franske førstdivision afholdes her. Stadionet tilbyder tværfaglige faciliteter til boksning, volleyball, bordtennis, squash, kampsport, basketball og meget mere.
          - Svømmebassiner
            - Centre nautique Prince Albert II: et olympisk bassin, et begynderbassin og en dykkerbrønd.
            - Piscine Saint-Charles: et svømmebassin beliggende i centrum af Monte-Carlo.
            - Stade de natation en plein air Rainier III: et svømmebad med olympisk bassin og vippe.
          - Andre sportsfaciliteter
            - Skøjtebanen: hver vinter forvandles Stade Nautique Rainier III til en 1.000m2 stor skøjtebane.
            - Monte-Carlo Country Club tilbyder 23 tennisbaner og er vært for en af verdens mest anerkendte tennisturneringer.

          ### 5. Kunst og kultur blomstrer i Monaco

          Den monegaskiske regering støtter aktivt kunst, kulturinstitutioner og humaniora gennem forskellige programmer og begivenheder. Fondation Prince Pierre blev skabt for at fremme litteratur- og kunstkulturen gennem oprettelse og tildeling af priser.

          **Kulturelle steder i Fyrstendømmet:**

          - La Compagnie des Ballets de Monte-Carlo
          - L'Orchestre Philharmonique de Monte-Carlo
          - L'Opéra de Monte-Carlo
          - Le Théâtre Princesse Grace
          - Le Printemps des Arts

          **Museer i Fyrstendømmet:**

          - Le Musée océanographique de Monaco
          - Le Musée d'Anthropologie Préhistorique
          - Le Musée des Timbres et des Monnaies
          - Le Nouveau Musée National de Monaco (N.M.N.M.)
          - Le Musée de la collection de voitures anciennes du Prince Rainier III
          - Le Musée Naval
          - Diverse udstillinger i Grimaldi Forum

          Godt at vide:

          En af de mest attraktive fordele ved at bo i Monaco er, at beboerne er fritaget for indkomstskat. Hvis du vil vide mere om den mulige indvirkning på dit privat- og professionelle liv, læs vores artikel om de unikke fordele ved Monacos skattesystem.

          Konkluderende tiltrækker Monacos fremragende omdømme investorer fra hele verden, hvilket får dets økonomi og beboere til at blomstre. Som følge heraf er levevilkårene i Monaco uovertrufne, og fattigdom er ikke-eksisterende i staten. Politisk stabilitet, lav arbejdsløshed og kriminalitet, sundhedspleje af høj kvalitet og statslige hjælpeprogrammer opretholder den høje levestandard i Monaco.

          Hvis du planlægger at bosætte dig der, her er en artikel om alt, du skal vide om at købe ejendom i Monaco.
        BODY
        "fi" => <<~BODY,
          Yli 300 aurinkoisella päivällä vuodessa Monacon ruhtinaskunnan asukkaat nauttivat Välimereltä, vesisporteista ja laskettelun iloista Etelä-Alppien hiihtokeskusten läheisyyden ansiosta. Ruhtinaskunnassa asumisen edut voisivat tuottaa loputtoman listan. Olemme kuitenkin koonneet teille 5 pääsyytä, miksi teidän tulisi muuttaa Monacoon.

          ### 1. Kadehdittava maantieteellinen sijainti ja ilmasto

          Monaco kohoaa ylpeänä kapealla Välimeren rannikon kaistaleella ja sitä reunustaa Ranska kolmelta sivulta. Sen pystysuora kaupunkimaisema erottaa sen välittömästi Alpes-Maritimesin esirinteiden vuorista. Monacon länsirannikolla lähellä sijaitsevat Nizzan, Cannesin ja Saint-Tropez'n kaupungit. Itäpuolella, Italian rajan takana, löydätte viehättäviä kaupunkeja kuten Bordighera, Sanremo ja Portofino.

          Ilmasto on myös korkealla Monacossa asumisen etulistan kärkipäässä noin 300 aurinkoisella päivällä vuodessa. Heinä- ja elokuussa lämpötilat ovat keskimäärin 27°C, ja jopa tammi- ja helmikuussa, viileimpinä kuukausina, keskilämpötilat yltävät 12°C:een.

          ### 2. Ruhtinaskunta on monimuotoinen ja kosmopoliittinen

          Lähes 120 kansallisuutta kahden neliökilometrin alueella keskittyneenä Monacolla on yksi maailman kosmopoliittisimmista väestöistä.

          Tämä mikrovaltion pinta-ala on 2,02km2. Osittain merestä vallattu se on Vatikaanin jälkeen maailman toiseksi pienin itsenäinen valtio. Monaco on myös todellinen Baabelin torni. Ranskalaiset, italialaiset, britit, sveitsiläiset ja belgialaiset muodostavat viisi suurinta ulkomaalaisten kansallisuusryhmää. Ulkomaalaiset asukkaat muodostavat kolme neljäsosaa ruhtinaskunnan kokonaisväestöstä — noin 38 000, verrattuna alle 9 000 monacalaiseen kansalaiseen.

          ### 3. Tehokas koulutusjärjestelmä

          Monacon koulutusjärjestelmä seuraa samaa opetussuunnitelmaa kuin Ranskan kansallinen koulutusjärjestelmä muutamin erityispiirtein:

          - Englannin kielen opetusta tehostetaan esikoulusta lukion viimeiseen vuoteen
          - Ranskaa opetetaan "vieraana kielenä" ei-ranskankielisten oppilaiden integraation helpottamiseksi
          - Kansallisen kulttuurin edistämistä tuetaan Monacon historian ja sen perinteisen kielen opetuksella
          - Liikuntakasvatusta tehostetaan pakollisella liikunta- ja uintiopetuksella varhaisesta iästä lähtien, kehittyneillä urheilulaitoksilla ja mukautetuilla aikatauluilla varustetuilla urheiluluokilla...

          Kouluinfrastruktuurin osalta ruhtinaskunnassa on:

          - 9 julkista koulutusinstituutiota: 6 esikoulua ja alakoulua, kaksi yläkoulua, yksi yleissivistävä ja teknologinen lukio sekä yksi ammatillinen ja hotelli- ja ravintola-alan lukio.
          - 11 päiväkotia: pienten lasten vanhemmille Monacon kunta tarjoaa 7 yhteisöllistä päiväkotia, 1 perhepäiväkodin, 3 mikropäiväkotia ja 1 varhaiskasvatuskeskuksen.
          - 2 yksityistä tunnustuskunnallista laitosta: mukaan lukien Institution François d'Assise - Nicolas Barré, yksityinen katolinen koulu, jossa on luokkia yläkoulusta lukioon.
          - International School of Monaco tarjoaa kaksikielistä englanti-ranska-opetusta esikoulusta lukioon.
          - Académie de Danse Princesse Grace
          - Korkeakoulututkintoja: International University of Monaco, kauppakorkeakoulu, École Supérieure d'Arts Plastiques ja Institut de Formation en Soins Infirmiers.

          Koulutus ruhtinaskunnassa on myös astunut digitaaliseen aikakauteen. Kaikki opettajat on varustettu kannettavilla tietokoneilla vuodesta 2019, yläkouluoppilaat kannettavalla tietokoneella tai tabletilla vuodesta 2020 ja lukiolaiset vuodesta 2021. Tämän digitaalisen integraation tavoitteena on edistää oppilaiden digitaalisten taitojen kehittymistä ja monipuolistaa oppimistapoja.

          Koulunkäyntiolosuhteet ovat myös olennainen tekijä koulutuksen menestyksessä ruhtinaskunnassa. Tilat ovat hyvin hoidettuja ja luokkahuoneet moderneja. Lisäksi niissä on enintään 25 oppilasta per luokkahuone, mikä edistää opettajien henkilökohtaista seurantaa jokaisen oppilaan kohdalla.

          Kaikki toteutetut toimenpiteet ja hallituksen investointi erinomaisen koulutusjärjestelmän edistämiseen Monacossa tuottavat poikkeuksellisia tuloksia, sillä ylioppilastutkinnon ja BTS:n läpäisyprosentit ylittävät 95% joka vuosi.

          ### 4. Intohimo urheiluun, monacalainen luonteenpiirre

          Ruhtinaskunnassa urheilulla on historiallisesti aina ollut suuri merkitys. Toistuvien urheilutapahtumien ja huipputason urheilulaitosten ansiosta intohimo urheiluun on kaikkialla läsnä asukkaiden keskuudessa.

          Monaco on saavuttanut kansainvälistä arvostusta tärkeänä keskuksena kaikenlaisille urheilutapahtumille, kuten Formula 1 Grand Prix, Rallye Monte-Carlo, Monte-Carlo Tennis Open, Herculis ja monet muut.

          **Mitä urheilulaitoksia Monacossa sijaitsee?**

          - Stadionit
            - Stade Louis II: kansainväliset ottelut ja Ranskan ensimmäisen divisioonan ottelut järjestetään täällä. Stadion tarjoaa monialaiset tilat nyrkkeilyyn, lentopalloon, pöytätennikseen, squashiin, kamppailulajeihin, koripalloon ja moniin muihin lajeihin.
          - Uima-altaat
            - Centre nautique Prince Albert II: olympia-allas, aloittelijoiden allas ja sukelluskaivo.
            - Piscine Saint-Charles: uima-allas Monte-Carlon keskustassa.
            - Stade de natation en plein air Rainier III: uimala, jossa on olympia-allas ja hyppytorni.
          - Muut urheilulaitokset
            - Luistinrata: joka talvi Stade Nautique Rainier III muuttuu 1 000m2 luistinradaksi.
            - Monte-Carlo Country Club tarjoaa 23 tenniskenttää ja isännöi yhtä maailman arvostetuimmista tennisturnauksista.

          ### 5. Taide ja kulttuuri kukoistavat Monacossa

          Monacon hallitus tukee aktiivisesti taiteita, kulttuurilaitoksia ja humanistisia tieteitä erilaisten ohjelmien ja tapahtumien kautta. Fondation Prince Pierre perustettiin edistämään kirjallisuuden ja taiteen kulttuuria luomalla ja myöntämällä palkintoja.

          **Ruhtinaskunnan kulttuuripaikat:**

          - La Compagnie des Ballets de Monte-Carlo
          - L'Orchestre Philharmonique de Monte-Carlo
          - L'Opéra de Monte-Carlo
          - Le Théâtre Princesse Grace
          - Le Printemps des Arts

          **Ruhtinaskunnan museot:**

          - Le Musée océanographique de Monaco
          - Le Musée d'Anthropologie Préhistorique
          - Le Musée des Timbres et des Monnaies
          - Le Nouveau Musée National de Monaco (N.M.N.M.)
          - Le Musée de la collection de voitures anciennes du Prince Rainier III
          - Le Musée Naval
          - Erilaisia näyttelyitä Grimaldi Forumissa

          Hyvä tietää:

          Yksi houkuttelevimmista eduista Monacossa asumisessa on se, että asukkaat on vapautettu tuloverosta. Jos haluatte tietää lisää sen mahdollisesta vaikutuksesta yksityis- ja ammatilliseen elämäänne, lukekaa artikkelimme Monacon verojärjestelmän ainutlaatuisista eduista.

          Yhteenvetona Monacon erinomainen maine houkuttelee sijoittajia ympäri maailmaa, mikä saa sen talouden ja asukkaat kukoistamaan. Tämän seurauksena elinolosuhteet Monacossa ovat vertaansa vailla, ja köyhyys on olematonta valtiossa. Poliittinen vakaus, alhainen työttömyys ja rikollisuus, laadukas terveydenhuolto ja valtion tukiohjelmat ylläpitävät Monacon korkeaa elintasoa.

          Jos suunnittelette muuttoa sinne, tässä on artikkeli kaikesta, mitä teidän tarvitsee tietää kiinteistöjen ostamisesta Monacossa.
        BODY
      }
    }

    # Article 2
    translations["les-avantages-uniques-du-systeme-fiscal-de-monaco"] = {
      title: {
        "en" => "The unique advantages of Monaco's tax system",
        "it" => "I vantaggi unici del sistema fiscale di Monaco",
        "de" => "Die einzigartigen Vorteile des Steuersystems von Monaco",
        "sv" => "De unika fördelarna med Monacos skattesystem",
        "no" => "De unike fordelene med Monacos skattesystem",
        "da" => "De unikke fordele ved Monacos skattesystem",
        "fi" => "Monacon verojärjestelmän ainutlaatuiset edut"
      },
      body: {
        "en" => <<~BODY,
          ### How does Monaco's tax system work?

          Monaco's tax system is unique and simple, as it operates without income tax and with a low business tax, which is a real advantage for individuals and foreign companies settling in the Principality.

          However, there are two exceptions to this near-total absence of taxation.

          ### What are the two exceptions to Monaco's tax system?

          #### Corporate profit tax

          Corporate profit tax is the only direct tax on companies in the Principality. It applies to companies generating less than 75% of their turnover in the Principality and therefore more than 25% outside of Monaco.

          It also applies to companies deriving their income from patents and artistic property rights and to companies engaged in commercial or industrial activities. These are subject to a tax rate of 33.33% on all corporate profits.

          #### Having French nationality

          All persons of French nationality who were not born in the Principality are subject to French income tax. This is due to the Principality's sole bilateral tax convention, the customs union between France and Monaco, established during the Franco-Monegasque Customs Convention of 1963.

          ### What are the tax laws for individuals in Monaco?

          Individuals are exempt from all income tax, capital gains tax or capital tax. This applies to:

          - persons of Monegasque nationality
          - natural persons of a nationality other than French and American officially residing in Monaco.
          - persons of French nationality born in the Principality who have never moved their tax address to France.
          - French citizens who can prove 5 years of residence in Monaco as of 31/10/1962

          ### How are inheritance and gift tax rights defined?

          In Monaco, when kinship is in direct line, the tax on inheritance or gift of property is 0%. Indeed, taxes on inheritances and gifts apply exclusively to property located in the Principality and differ according to the specific degree of kinship between the testator and the heir or the donor and the recipient.

          - in direct line such as parents and children or spouses: 0%.
          - between brothers and sisters: 8%.
          - between uncles, aunts, nephews and nieces: 10%.
          - between other types of relatives: 13%
          - between unrelated persons: 16%

          ### What you need to know about stamp and registration duties in the Principality

          #### Registration duties

          Registration duties are collected during registration formalities, concerning transfers or civil or judicial acts. Acts that must be registered within mandatory deadlines include, for example:

          - Notarial acts
          - Judicial acts
          - Extra-judicial acts
          - Succession declarations (wills)
          - Lease agreements
          - Transfer of real estate
          - Sale of businesses

          #### Stamp duties

          Stamp duty is a tax that applies to all papers intended for civil and judicial acts and writings that may be produced in court as evidence. It serves as a means of collection for administrative formalities such as:

          - certificate of domicile
          - work permit
          - family record book
          - passport...

          Stamp duties are generally fixed, but the price may vary depending on the size of the paper or the values expressed in the acts.

          In conclusion, settling in Monaco could most certainly have a particularly positive impact on your tax situation, not only in the private context but also in the professional context. You thus enhance your income and increase your potential for purchasing property in one of the Principality's districts.
        BODY
        "it" => <<~BODY,
          ### Come funziona il sistema fiscale di Monaco?

          Il sistema fiscale monegasco è unico e semplice, poiché funziona senza imposta sul reddito e con una bassa tassa professionale, il che rappresenta un reale vantaggio per i privati e le imprese straniere che si stabiliscono nel Principato.

          Tuttavia, esistono due eccezioni a questa quasi totale assenza di imposizione fiscale.

          ### Quali sono le due eccezioni al sistema fiscale di Monaco?

          #### L'imposta sugli utili delle imprese

          L'imposta sugli utili delle imprese è l'unica imposta diretta sulle società nel Principato. Si applica alle imprese che realizzano meno del 75% del loro fatturato nel Principato e quindi più del 25% al di fuori di Monaco.

          Si applica inoltre alle società che traggono i loro redditi da brevetti e diritti di proprietà artistica e alle società che esercitano un'attività commerciale o industriale. Queste ultime sono soggette a un'aliquota del 33,33% sull'insieme degli utili societari.

          #### Avere la nazionalità francese

          Tutte le persone di nazionalità francese che non sono nate nel Principato sono soggette all'imposta francese sul reddito. Ciò è dovuto all'unica convenzione fiscale bilaterale del Principato, l'unione doganale tra la Francia e Monaco, stabilita con la Convenzione doganale franco-monegasca del 1963.

          ### Quali sono le leggi fiscali per i privati a Monaco?

          I privati sono esenti da ogni imposta sul reddito, sulle plusvalenze o sul capitale. Si tratta di:

          - persone di nazionalità monegasca
          - persone fisiche di nazionalità diversa da quella francese e americana che risiedono ufficialmente a Monaco.
          - persone di nazionalità francese nate nel Principato e che non hanno mai trasferito il loro domicilio fiscale in Francia.
          - francesi che possono giustificare 5 anni di residenza a Monaco al 31/10/1962

          ### Come sono definiti i diritti di successione e donazione?

          A Monaco, quando la parentela è in linea diretta, l'imposta sulla successione o la donazione di beni è dello 0%. In effetti, le imposte sulle successioni e le donazioni si applicano esclusivamente ai beni situati nel Principato e differiscono in base al grado specifico di parentela tra il testatore e l'erede o il donante e il donatario.

          - in linea diretta come genitori e figli o coniugi: 0%.
          - tra fratelli e sorelle: 8%.
          - tra zii, zie, nipoti: 10%.
          - tra altri tipi di parenti: 13%
          - tra persone non imparentate: 16%

          ### Cosa c'è da sapere sui diritti di bollo e di registrazione nel Principato

          #### I diritti di registrazione

          I diritti di registrazione sono riscossi durante le formalità di registrazione, riguardanti trasferimenti o atti civili o giudiziari. Gli atti obbligatoriamente soggetti a registrazione entro termini imperativi sono ad esempio:

          - Gli atti notarili
          - Gli atti giudiziari
          - Gli atti extra-giudiziari
          - Le dichiarazioni di successione (testamenti)
          - I contratti di locazione
          - La cessione di beni immobiliari
          - Le vendite di imprese

          #### I diritti di bollo

          Il diritto di bollo è un'imposta che si applica a tutti i documenti destinati ad atti civili e giudiziari e alle scritture che possono essere prodotte in giudizio come prova. Serve come mezzo di riscossione per le formalità amministrative quali:

          - certificato di domicilio
          - permesso di lavoro
          - libretto di famiglia
          - passaporto...

          I diritti di bollo sono generalmente fissi, ma il prezzo può variare in funzione della dimensione del foglio o dei valori espressi negli atti.

          In conclusione, stabilirsi a Monaco potrebbe certamente avere un impatto particolarmente positivo sulla vostra situazione fiscale, non solo nel contesto privato, ma anche in quello professionale. Valorizzate così i vostri redditi e aumentate il vostro potenziale di acquisto di un immobile in uno dei quartieri del Principato.
        BODY
        "de" => <<~BODY,
          ### Wie funktioniert das Steuersystem von Monaco?

          Das monegassische Steuersystem ist einzigartig und einfach, da es ohne Einkommensteuer und mit einer niedrigen Gewerbesteuer funktioniert, was ein echter Vorteil für Privatpersonen und ausländische Unternehmen ist, die sich im Fürstentum niederlassen.

          Es gibt jedoch zwei Ausnahmen von dieser nahezu vollständigen Steuerfreiheit.

          ### Welche zwei Ausnahmen gibt es im Steuersystem von Monaco?

          #### Die Unternehmensgewinnsteuer

          Die Unternehmensgewinnsteuer ist die einzige direkte Steuer auf Unternehmen im Fürstentum. Sie gilt für Unternehmen, die weniger als 75% ihres Umsatzes im Fürstentum und damit mehr als 25% außerhalb von Monaco erzielen.

          Sie gilt auch für Gesellschaften, die ihre Einkünfte aus Patenten und künstlerischen Eigentumsrechten beziehen, und für Gesellschaften, die eine gewerbliche oder industrielle Tätigkeit ausüben. Diese unterliegen einem Steuersatz von 33,33% auf alle Unternehmensgewinne.

          #### Besitz der französischen Staatsangehörigkeit

          Alle Personen mit französischer Staatsangehörigkeit, die nicht im Fürstentum geboren wurden, unterliegen der französischen Einkommensteuer. Dies ist auf das einzige bilaterale Steuerabkommen des Fürstentums zurückzuführen, die Zollunion zwischen Frankreich und Monaco, die im Rahmen des französisch-monegassischen Zollabkommens von 1963 geschlossen wurde.

          ### Welche Steuergesetze gelten für Privatpersonen in Monaco?

          Privatpersonen sind von allen Einkommensteuern, Kapitalertragsteuern oder Vermögenssteuern befreit. Dies betrifft:

          - Personen monegassischer Staatsangehörigkeit
          - natürliche Personen mit einer anderen als der französischen und amerikanischen Staatsangehörigkeit, die offiziell in Monaco wohnhaft sind.
          - Personen französischer Staatsangehörigkeit, die im Fürstentum geboren sind und ihren steuerlichen Wohnsitz nie nach Frankreich verlegt haben.
          - Franzosen, die 5 Jahre Wohnsitz in Monaco zum 31.10.1962 nachweisen können

          ### Wie sind Erbschafts- und Schenkungssteuerrechte definiert?

          In Monaco beträgt die Steuer auf Erbschaft oder Schenkung in direkter Linie 0%. Die Steuern auf Erbschaften und Schenkungen gelten ausschließlich für Vermögenswerte im Fürstentum und unterscheiden sich je nach dem spezifischen Verwandtschaftsgrad zwischen dem Erblasser und dem Erben oder dem Schenker und dem Beschenkten.

          - in direkter Linie wie Eltern und Kinder oder Ehegatten: 0%.
          - zwischen Geschwistern: 8%.
          - zwischen Onkeln, Tanten, Neffen und Nichten: 10%.
          - zwischen anderen Verwandten: 13%
          - zwischen nicht verwandten Personen: 16%

          ### Was Sie über Stempel- und Registrierungsgebühren im Fürstentum wissen müssen

          #### Die Registrierungsgebühren

          Registrierungsgebühren werden bei Registrierungsformalitäten erhoben, die Übertragungen oder zivil- oder gerichtliche Akte betreffen. Akte, die innerhalb zwingender Fristen registriert werden müssen, sind beispielsweise:

          - Notarielle Urkunden
          - Gerichtliche Akte
          - Außergerichtliche Akte
          - Erbschaftserklärungen (Testamente)
          - Mietverträge
          - Übertragung von Immobilien
          - Unternehmensverkäufe

          #### Die Stempelgebühren

          Die Stempelgebühr ist eine Steuer, die auf alle Papiere erhoben wird, die für zivil- und gerichtliche Akte bestimmt sind und die als Beweis vor Gericht vorgelegt werden können. Sie dient als Erhebungsmittel für Verwaltungsformalitäten wie:

          - Wohnsitzbescheinigung
          - Arbeitserlaubnis
          - Familienstammbuch
          - Reisepass...

          Stempelgebühren sind in der Regel fest, aber der Preis kann je nach Papiergröße oder den in den Akten ausgedrückten Werten variieren.

          Zusammenfassend könnte eine Niederlassung in Monaco zweifellos einen besonders positiven Einfluss auf Ihre steuerliche Situation haben, nicht nur im privaten, sondern auch im beruflichen Kontext. Sie steigern so Ihre Einkünfte und erhöhen Ihr Kaufpotenzial für eine Immobilie in einem der Viertel des Fürstentums.
        BODY
        "sv" => <<~BODY,
          ### Hur fungerar Monacos skattesystem?

          Monacos skattesystem är unikt och enkelt, eftersom det fungerar utan inkomstskatt och med en låg företagsskatt, vilket är en verklig fördel för privatpersoner och utländska företag som etablerar sig i Furstendömet.

          Det finns dock två undantag från denna nästan totala frånvaro av beskattning.

          ### Vilka är de två undantagen i Monacos skattesystem?

          #### Skatt på företagsvinster

          Skatt på företagsvinster är den enda direkta skatten på företag i Furstendömet. Den gäller för företag som genererar mindre än 75% av sin omsättning i Furstendömet och därmed mer än 25% utanför Monaco.

          Den gäller också för bolag som härleder sina inkomster från patent och konstnärliga äganderätter och för bolag som bedriver kommersiell eller industriell verksamhet. Dessa är föremål för en skattesats på 33,33% på alla företagsvinster.

          #### Att ha franskt medborgarskap

          Alla personer med franskt medborgarskap som inte är födda i Furstendömet omfattas av fransk inkomstskatt. Detta beror på Furstendömets enda bilaterala skatteavtal, tullunionen mellan Frankrike och Monaco, som upprättades under den fransk-monegaskiska tullkonventionen 1963.

          ### Vilka skattelagar gäller för privatpersoner i Monaco?

          Privatpersoner är befriade från all inkomstskatt, kapitalvinstskatt och kapitalskatt. Detta gäller:

          - personer med monegaskiskt medborgarskap
          - fysiska personer med annan nationalitet än fransk och amerikansk som officiellt är bosatta i Monaco.
          - personer med franskt medborgarskap födda i Furstendömet som aldrig har flyttat sin skatteadress till Frankrike.
          - fransmän som kan bevisa 5 års bosättning i Monaco per 31/10/1962

          ### Hur definieras arvs- och gåvoskatterätter?

          I Monaco, när släktskapet är i rakt nedstigande led, är skatten på arv eller gåva av egendom 0%. Skatter på arv och gåvor gäller uteslutande egendom belägen i Furstendömet och varierar beroende på den specifika graden av släktskap mellan testatorn och arvingen eller givaren och mottagaren.

          - i rakt nedstigande led såsom föräldrar och barn eller makar: 0%.
          - mellan syskon: 8%.
          - mellan farbröder, mostrar, syskonbarn: 10%.
          - mellan andra typer av släktingar: 13%
          - mellan icke-besläktade personer: 16%

          ### Vad du behöver veta om stämpel- och registreringsavgifter i Furstendömet

          #### Registreringsavgifter

          Registreringsavgifter uppbärs vid registreringsformaliteter avseende överlåtelser eller civilrättsliga eller rättsliga handlingar. Handlingar som obligatoriskt måste registreras inom tvingande tidsfrister är till exempel:

          - Notarialhandlingar
          - Rättsliga handlingar
          - Utomrättsliga handlingar
          - Arvsdeklarationer (testamenten)
          - Hyreskontrakt
          - Överlåtelse av fastigheter
          - Försäljning av företag

          #### Stämpelavgifter

          Stämpelavgiften är en skatt som gäller för alla papper avsedda för civilrättsliga och rättsliga handlingar och skrivelser som kan åberopas som bevis i domstol. Den tjänar som uppbördsmedel för administrativa formaliteter såsom:

          - bostadsbevis
          - arbetstillstånd
          - familjebok
          - pass...

          Stämpelavgifter är i allmänhet fasta, men priset kan variera beroende på papperets storlek eller de värden som uttrycks i handlingarna.

          Sammanfattningsvis kan en bosättning i Monaco med största sannolikhet ha en särskilt positiv inverkan på din skattesituation, inte bara i det privata utan även i det professionella sammanhanget. Du ökar därigenom dina inkomster och ökar din potential att köpa en fastighet i ett av Furstendömets kvarter.
        BODY
        "no" => <<~BODY,
          ### Hvordan fungerer Monacos skattesystem?

          Monacos skattesystem er unikt og enkelt, ettersom det fungerer uten inntektsskatt og med lav næringsskatt, noe som er en reell fordel for privatpersoner og utenlandske selskaper som etablerer seg i Fyrstedømmet.

          Det finnes imidlertid to unntak fra dette nesten totale fraværet av beskatning.

          ### Hva er de to unntakene i Monacos skattesystem?

          #### Skatt på selskapers overskudd

          Skatt på selskapers overskudd er den eneste direkte skatten på selskaper i Fyrstedømmet. Den gjelder for selskaper som genererer mindre enn 75% av omsetningen i Fyrstedømmet og dermed mer enn 25% utenfor Monaco.

          Den gjelder også for selskaper som henter inntektene sine fra patenter og kunstneriske eiendomsrettigheter, og for selskaper som driver kommersiell eller industriell virksomhet. Disse er underlagt en skattesats på 33,33% på alle selskapers overskudd.

          #### Å ha fransk statsborgerskap

          Alle personer med fransk statsborgerskap som ikke er født i Fyrstedømmet er underlagt fransk inntektsskatt. Dette skyldes Fyrstedømmets eneste bilaterale skatteavtale, tollunionen mellom Frankrike og Monaco, etablert under den fransk-monegaskiske tollkonvensjonen av 1963.

          ### Hvilke skattelover gjelder for privatpersoner i Monaco?

          Privatpersoner er fritatt for all inntektsskatt, kapitalgevinstskatt eller formuesskatt. Dette gjelder:

          - personer med monegaskisk statsborgerskap
          - fysiske personer med annen nasjonalitet enn fransk og amerikansk som offisielt er bosatt i Monaco.
          - personer med fransk statsborgerskap født i Fyrstedømmet som aldri har flyttet sin skatteadresse til Frankrike.
          - franskmenn som kan dokumentere 5 års botid i Monaco per 31.10.1962

          ### Hvordan er arve- og gaverettigheter definert?

          I Monaco, når slektskapet er i direkte linje, er skatten på arv eller gave av eiendom 0%. Skatter på arv og gaver gjelder utelukkende eiendeler som befinner seg i Fyrstedømmet og varierer i henhold til den spesifikke slektskapsgaden mellom testator og arving eller giver og mottaker.

          - i direkte linje som foreldre og barn eller ektefeller: 0%.
          - mellom søsken: 8%.
          - mellom onkler, tanter, nevøer og nieser: 10%.
          - mellom andre typer slektninger: 13%
          - mellom ikke-beslektede personer: 16%

          ### Hva du trenger å vite om stempel- og registreringsavgifter i Fyrstedømmet

          #### Registreringsavgifter

          Registreringsavgifter kreves inn under registreringsformaliteter vedrørende overdragelser eller sivile eller rettslige handlinger. Handlinger som obligatorisk må registreres innen tvingende frister er for eksempel:

          - Notarialhandlinger
          - Rettslige handlinger
          - Utenrettslige handlinger
          - Arvedeklarasjoner (testamenter)
          - Leiekontrakter
          - Overdragelse av fast eiendom
          - Salg av virksomheter

          #### Stempelavgifter

          Stempelavgiften er en skatt som gjelder for alle papirer beregnet på sivile og rettslige handlinger og skrifter som kan fremlegges i retten som bevis. Den tjener som innkrevingsmiddel for administrative formaliteter som:

          - bostedsattest
          - arbeidstillatelse
          - familiestambok
          - pass...

          Stempelavgifter er generelt faste, men prisen kan variere avhengig av papirets størrelse eller verdiene uttrykt i handlingene.

          Avslutningsvis kan en bosettelse i Monaco med stor sannsynlighet ha en særlig positiv innvirkning på din skattesituasjon, ikke bare i privat sammenheng, men også i profesjonell sammenheng. Du øker dermed dine inntekter og øker ditt potensial for å kjøpe en eiendom i et av Fyrstedømmets kvarterer.
        BODY
        "da" => <<~BODY,
          ### Hvordan fungerer Monacos skattesystem?

          Monacos skattesystem er unikt og enkelt, da det fungerer uden indkomstskat og med en lav erhvervsskat, hvilket er en reel fordel for privatpersoner og udenlandske virksomheder, der etablerer sig i Fyrstendømmet.

          Der er dog to undtagelser fra dette næsten totale fravær af beskatning.

          ### Hvad er de to undtagelser i Monacos skattesystem?

          #### Skat på virksomheders overskud

          Skat på virksomheders overskud er den eneste direkte skat på selskaber i Fyrstendømmet. Den gælder for virksomheder, der genererer mindre end 75% af deres omsætning i Fyrstendømmet og dermed mere end 25% uden for Monaco.

          Den gælder også for selskaber, der henter deres indkomst fra patenter og kunstneriske ejendomsrettigheder, og for selskaber, der driver kommerciel eller industriel virksomhed. Disse er underlagt en skattesats på 33,33% af alle virksomheders overskud.

          #### At have fransk statsborgerskab

          Alle personer med fransk statsborgerskab, der ikke er født i Fyrstendømmet, er underlagt fransk indkomstskat. Dette skyldes Fyrstendømmets eneste bilaterale skatteaftale, toldunionen mellem Frankrig og Monaco, etableret under den fransk-monegaskiske toldkonvention i 1963.

          ### Hvilke skattelove gælder for privatpersoner i Monaco?

          Privatpersoner er fritaget for al indkomstskat, kapitalgevinstskat eller kapitalskat. Dette gælder:

          - personer med monegaskisk statsborgerskab
          - fysiske personer med anden nationalitet end fransk og amerikansk, der officielt er bosiddende i Monaco.
          - personer med fransk statsborgerskab, født i Fyrstendømmet, der aldrig har flyttet deres skatteadresse til Frankrig.
          - franskmænd, der kan dokumentere 5 års bopæl i Monaco pr. 31/10/1962

          ### Hvordan er arve- og gaverettigheder defineret?

          I Monaco, når slægtskabet er i direkte linje, er skatten på arv eller gave af ejendom 0%. Skatter på arv og gaver gælder udelukkende ejendom beliggende i Fyrstendømmet og varierer alt efter den specifikke grad af slægtskab mellem testator og arving eller giver og modtager.

          - i direkte linje såsom forældre og børn eller ægtefæller: 0%.
          - mellem søskende: 8%.
          - mellem onkler, tanter, nevøer og niecer: 10%.
          - mellem andre typer slægtninge: 13%
          - mellem ikke-beslægtede personer: 16%

          ### Hvad du skal vide om stempel- og registreringsafgifter i Fyrstendømmet

          #### Registreringsafgifter

          Registreringsafgifter opkræves ved registreringsformaliteter vedrørende overdragelser eller civile eller retslige handlinger. Handlinger, der obligatorisk skal registreres inden for tvingende frister, er f.eks.:

          - Notarialhandlinger
          - Retslige handlinger
          - Udenretslige handlinger
          - Arvedeklarationer (testamenter)
          - Lejekontrakter
          - Overdragelse af fast ejendom
          - Salg af virksomheder

          #### Stempelafgifter

          Stempelafgiften er en skat, der gælder for alle papirer beregnet til civile og retslige handlinger og skrifter, der kan fremlægges i retten som bevis. Den tjener som opkrævningsmiddel for administrative formaliteter som:

          - bopælsattest
          - arbejdstilladelse
          - familiebog
          - pas...

          Stempelafgifter er generelt faste, men prisen kan variere afhængigt af papirets størrelse eller de værdier, der er udtrykt i handlingerne.

          Konkluderende kan en bosættelse i Monaco med stor sandsynlighed have en særligt positiv indvirkning på din skattesituation, ikke kun i privat sammenhæng, men også i professionel sammenhæng. Du øger dermed dine indtægter og øger dit potentiale for at købe en ejendom i et af Fyrstendømmets kvarterer.
        BODY
        "fi" => <<~BODY,
          ### Miten Monacon verojärjestelmä toimii?

          Monacon verojärjestelmä on ainutlaatuinen ja yksinkertainen, sillä se toimii ilman tuloveroa ja alhaisella elinkeinoverolla, mikä on todellinen etu ruhtinaskuntaan asettuville yksityishenkilöille ja ulkomaisille yrityksille.

          On kuitenkin olemassa kaksi poikkeusta tähän lähes täydelliseen verotuksen puuttumiseen.

          ### Mitkä ovat Monacon verojärjestelmän kaksi poikkeusta?

          #### Yritysten voittovero

          Yritysten voittovero on ainoa suora vero yrityksille ruhtinaskunnassa. Se koskee yrityksiä, jotka tuottavat alle 75% liikevaihdostaan ruhtinaskunnassa ja siten yli 25% Monacon ulkopuolella.

          Se koskee myös yhtiöitä, jotka saavat tulonsa patenteista ja taiteellisista omistusoikeuksista, sekä kaupallista tai teollista toimintaa harjoittavia yhtiöitä. Nämä ovat 33,33% verokannassa kaikista yritysten voitoista.

          #### Ranskan kansalaisuuden omaaminen

          Kaikki Ranskan kansalaiset, jotka eivät ole syntyneet ruhtinaskunnassa, ovat Ranskan tuloveron alaisia. Tämä johtuu ruhtinaskunnan ainoasta kahdenvälisestä verosopimuksesta, Ranskan ja Monacon välisestä tulliliitosta, joka perustettiin Ranskan ja Monacon välisessä tullisopimuksessa vuonna 1963.

          ### Mitä verolakeja sovelletaan yksityishenkilöihin Monacossa?

          Yksityishenkilöt on vapautettu kaikista tuloveroista, luovutusvoittoveroista tai pääomaveroista. Tämä koskee:

          - monacalaisen kansalaisuuden omaavia henkilöitä
          - muita kuin Ranskan ja Amerikan kansalaisuuden omaavia luonnollisia henkilöitä, jotka asuvat virallisesti Monacossa.
          - Ranskan kansalaisuuden omaavia henkilöitä, jotka ovat syntyneet ruhtinaskunnassa eivätkä ole koskaan siirtäneet verotuspaikkansa Ranskaan.
          - ranskalaisia, jotka voivat todistaa 5 vuoden asumisen Monacossa 31.10.1962 mennessä

          ### Miten perintö- ja lahjavero-oikeudet on määritelty?

          Monacossa, kun sukulaisuus on suorassa linjassa, perintö- tai lahjavero on 0%. Perintö- ja lahjavero koskevat yksinomaan ruhtinaskunnassa sijaitsevia omaisuuseriä ja vaihtelevat testamentin tekijän ja perillisen tai lahjoittajan ja saajan välisen sukulaisuusasteen mukaan.

          - suorassa linjassa kuten vanhemmat ja lapset tai puolisot: 0%.
          - sisarusten välillä: 8%.
          - setien, tätien, veljenpoikien ja sisarentyttärien välillä: 10%.
          - muiden sukulaisten välillä: 13%
          - sukulaisuussuhteessa olemattomien henkilöiden välillä: 16%

          ### Mitä sinun tulee tietää leima- ja rekisteröintimaksuista ruhtinaskunnassa

          #### Rekisteröintimaksut

          Rekisteröintimaksut peritään rekisteröintiformaliteettien yhteydessä, jotka koskevat luovutuksia tai siviili- tai oikeudellisia asiakirjoja. Pakollisesti rekisteröitäviin asiakirjoihin pakollisten määräaikojen sisällä kuuluvat esimerkiksi:

          - Notaariasiakirjat
          - Oikeudenkäyntiasiakirjat
          - Tuomioistuimen ulkopuoliset asiakirjat
          - Perintöilmoitukset (testamentit)
          - Vuokrasopimukset
          - Kiinteistöjen luovutukset
          - Yritysten myynnit

          #### Leimaverot

          Leimavero on vero, joka koskee kaikkia siviili- ja oikeudellisiin toimiin tarkoitettuja asiakirjoja ja kirjoituksia, jotka voidaan esittää todisteena oikeudessa. Se toimii hallinnollisten formaliteettien perintäkeinona, kuten:

          - asuinpaikkatodistus
          - työlupa
          - perheen rekisterikirja
          - passi...

          Leimaverot ovat yleensä kiinteitä, mutta hinta voi vaihdella paperin koon tai asiakirjoissa ilmaistujen arvojen mukaan.

          Yhteenvetona voidaan todeta, että Monacoon asettuminen voisi mitä todennäköisimmin vaikuttaa erityisen myönteisesti verotustilanteeseenne, ei vain yksityiselämässä, vaan myös ammatillisessa kontekstissa. Lisäätte siten tulojanne ja kasvatatte mahdollisuuksianne ostaa kiinteistö yhdessä ruhtinaskunnan kaupunginosista.
        BODY
      }
    }

    # Apply translations - merge with existing French content
    translations.each do |slug, data|
      article = Article.find_by(slug: slug)
      unless article
        puts "  SKIP: Article '#{slug}' not found"
        next
      end

      article.title = article.title.merge(data[:title])
      article.body = article.body.merge(data[:body])
      article.save!
      puts "  OK: #{slug} (#{article.title.keys.sort.join(', ')})"
    end

    puts "\nDone! Translated #{translations.size} articles."
  end
end
