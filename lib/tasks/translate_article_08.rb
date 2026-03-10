# rails runner lib/tasks/translate_article_08.rb
article = Article.find_by!(slug: "quelles-sont-les-conditions-a-remplir-pour-s-installer-a-monaco")

article.title = article.title.merge(
  "en" => "What are the requirements for settling in Monaco?",
  "it" => "Quali sono le condizioni da soddisfare per stabilirsi a Monaco?",
  "de" => "Welche Voraussetzungen müssen erfüllt werden, um sich in Monaco niederzulassen?",
  "sv" => "Vilka krav måste uppfyllas för att bosätta sig i Monaco?",
  "no" => "Hvilke krav må oppfylles for å bosette seg i Monaco?",
  "da" => "Hvilke betingelser skal opfyldes for at bosætte sig i Monaco?",
  "fi" => "Mitä ehtoja Monacoon muuttaminen edellyttää?"
)

article.body = article.body.merge(
  "en" => <<~BODY,
    Settling in the Principality as an expatriate or to become a permanent resident requires a thorough knowledge of the procedure to follow and the conditions to meet. In this article, you will find all the important information you need to know to settle in Monaco.

    ### Staying in Monaco for less than 3 months

    Foreigners planning to stay in Monaco for a maximum of three months per year generally only need an identity document, such as an identity card or a travel passport. For non-Europeans, the same document required to enter France is needed.

    ### Staying in Monaco for more than 3 months

    #### Requirements for Europeans:

    For European citizens, with the exception of French residents planning to stay more than three months in the Principality, the following evidence is required to obtain an official residence permit from the Public Security Department:

    - Proof of accommodation in Monaco (it can be rented or owned).
    - Proof of sufficient financial resources such as:
      - An employment contract
      - An authorised document stating that you are a company director, self-employed, etc.
      - A bank certificate
      - Proof of support from a third party
      - Proof of sufficient savings
    - Proof of good character, such as:
      - An extract from your criminal record
      - A sworn statement certifying that you have never been convicted before.

    European residents do not need to apply for a visa to settle in Monaco.

    #### Requirements for non-Europeans:

    If you are a citizen of a state that is not part of the European Economic Area, you will need to apply for a visa to come to Monaco by submitting the following documents to the French consulate:

    - Proof of accommodation in Monaco (it can be rented, owned or promised).
    - Proof of sufficient financial resources such as:
      - An employment contract
      - An authorised document stating that you are a company director, self-employed, etc.
      - A bank certificate
      - Proof of support from a third party
      - Proof of sufficient savings
    - Proof of good character, such as:
      - An extract from your criminal record
      - A sworn statement certifying that you have never been convicted before.
    - Identity documents
    - The long-stay visa application form

    Once you have obtained the visa, you must apply for the official residence permit from the Public Security Department, following the same procedure as European nationals.

    However, if you have been staying in France before your move to Monaco, the procedure is slightly different.

    ### Applicants who have been staying in France for more than one year

    If you are a national of a non-European Economic Area state and have been residing in France for more than one year, here is what you need to do:

    - Submit the settlement application to the French Embassy in Monaco.
    - Present a copy of the French residence permit

    ### Applicants who have been staying in France for less than one year

    As a non-European national staying in France for less than one year, you must follow the rules applicable to foreigners from states outside the European Economic Area and submit your visa application to the French consulate.

    Overall, the formal application procedure is pleasantly straightforward and, above all, well worth it! The Principality offers the advantages of an unparalleled tax system, an exceptionally high standard of living, the most prestigious environment you could ask for, and visa-free access to all Schengen states for its residents.
  BODY
  "it" => <<~BODY,
    Stabilirsi nel Principato come espatriato o per diventare residente permanente richiede una conoscenza approfondita della procedura da seguire e delle condizioni da soddisfare. In questo articolo troverete tutte le informazioni importanti da conoscere per stabilirvi a Monaco.

    ### Soggiornare a Monaco per meno di 3 mesi

    Gli stranieri che prevedono di soggiornare a Monaco per un massimo di tre mesi all'anno necessitano generalmente solo di un documento d'identità, come una carta d'identità o un passaporto. Per i non europei, è richiesto lo stesso documento necessario per entrare in Francia.

    ### Soggiornare a Monaco per più di 3 mesi

    #### Requisiti per gli europei:

    Per i cittadini europei, ad eccezione dei residenti francesi che prevedono di soggiornare per più di tre mesi nel Principato, sono richieste le seguenti prove per ottenere un permesso di soggiorno ufficiale presso la Pubblica Sicurezza:

    - Una prova di alloggio a Monaco (può essere in affitto o di proprietà).
    - Una prova di risorse finanziarie sufficienti come:
      - Un contratto di lavoro
      - Un documento autorizzato che attesti che siete direttori della vostra società, lavoratori autonomi, ecc.
      - Un certificato bancario
      - Prova del sostegno di una terza persona
      - Prova di risparmi sufficienti
    - Prova di buona condotta, come:
      - Un estratto del casellario giudiziale
      - Un certificato d'onore attestante che non siete mai stati condannati in precedenza.

    I residenti europei non hanno bisogno di richiedere un visto per stabilirsi a Monaco.

    #### Requisiti per i non europei:

    Se siete cittadini di uno Stato che non fa parte dello Spazio economico europeo, dovrete richiedere un visto per venire a Monaco presentando i seguenti documenti al consolato francese:

    - Un giustificativo di alloggio a Monaco (può essere in affitto, di proprietà o promesso).
    - Una prova di risorse finanziarie sufficienti come:
      - Un contratto di lavoro
      - Un documento autorizzato che attesti che siete direttori della vostra società, lavoratori autonomi, ecc.
      - Un certificato bancario
      - Prova del sostegno di un terzo
      - Prova di risparmi sufficienti
    - Prova di buona condotta, come:
      - Un estratto del casellario giudiziale
      - Un certificato d'onore attestante che non siete mai stati condannati in precedenza.
    - Documenti d'identità
    - Il modulo di richiesta del visto per soggiorno di lunga durata

    Non appena avrete ottenuto il visto, dovrete richiedere il permesso di soggiorno ufficiale presso la Pubblica Sicurezza, seguendo la stessa procedura dei cittadini europei.

    Tuttavia, se avete soggiornato in Francia prima del vostro trasferimento a Monaco, la procedura è leggermente diversa.

    ### Richiedenti che soggiornano in Francia da più di un anno

    Se siete cittadini di uno Stato non membro dello Spazio economico europeo e risiedete in Francia da più di un anno, ecco cosa dovete fare:

    - Depositare la domanda di insediamento presso l'ambasciata di Francia a Monaco.
    - Presentare una copia del permesso di soggiorno francese

    ### Richiedenti che soggiornano in Francia da meno di un anno

    In qualità di cittadini non europei che soggiornano in Francia da meno di un anno, dovete seguire le regole applicabili agli stranieri provenienti da Stati al di fuori dello Spazio economico europeo e depositare la vostra domanda di visto presso il consolato francese.

    Nel complesso, la procedura formale di domanda è piacevolmente semplice e soprattutto ne vale la pena! Il Principato offre i vantaggi di un sistema fiscale incomparabile, un livello di vita eccezionalmente elevato, l'ambiente più prestigioso che possiate desiderare e un accesso senza visto a tutti gli Stati Schengen per i suoi residenti.
  BODY
  "de" => <<~BODY,
    Sich im Fürstentum als Expatriate niederzulassen oder ständiger Einwohner zu werden, erfordert eine gründliche Kenntnis des einzuhaltenden Verfahrens und der zu erfüllenden Bedingungen. In diesem Artikel finden Sie alle wichtigen Informationen, die Sie kennen müssen, um sich in Monaco niederzulassen.

    ### Aufenthalt in Monaco für weniger als 3 Monate

    Ausländer, die planen, sich höchstens drei Monate pro Jahr in Monaco aufzuhalten, benötigen in der Regel nur ein Ausweisdokument, wie einen Personalausweis oder einen Reisepass. Für Nicht-Europäer ist dasselbe Dokument erforderlich, das für die Einreise nach Frankreich benötigt wird.

    ### Aufenthalt in Monaco für mehr als 3 Monate

    #### Anforderungen für Europäer:

    Für europäische Staatsbürger, mit Ausnahme französischer Einwohner, die planen, sich mehr als drei Monate im Fürstentum aufzuhalten, sind folgende Nachweise erforderlich, um eine offizielle Aufenthaltserlaubnis bei der öffentlichen Sicherheitsbehörde zu erhalten:

    - Ein Nachweis über eine Unterkunft in Monaco (sie kann gemietet oder im Besitz sein).
    - Ein Nachweis über ausreichende finanzielle Mittel wie:
      - Ein Arbeitsvertrag
      - Ein autorisiertes Dokument, das bestätigt, dass Sie Geschäftsführer Ihres Unternehmens, Selbstständiger usw. sind.
      - Eine Bankbescheinigung
      - Nachweis der Unterstützung durch eine dritte Person
      - Nachweis über ausreichende Ersparnisse
    - Nachweis der Unbescholtenheit, wie:
      - Ein Auszug aus Ihrem Strafregister
      - Eine eidesstattliche Erklärung, dass Sie noch nie verurteilt wurden.

    Europäische Einwohner müssen kein Visum beantragen, um sich in Monaco niederzulassen.

    #### Anforderungen für Nicht-Europäer:

    Wenn Sie Staatsbürger eines Staates sind, der nicht zum Europäischen Wirtschaftsraum gehört, müssen Sie ein Visum beantragen, um nach Monaco zu kommen, indem Sie folgende Dokumente beim französischen Konsulat einreichen:

    - Ein Nachweis über eine Unterkunft in Monaco (sie kann gemietet, im Besitz oder zugesagt sein).
    - Ein Nachweis über ausreichende finanzielle Mittel wie:
      - Ein Arbeitsvertrag
      - Ein autorisiertes Dokument, das bestätigt, dass Sie Geschäftsführer Ihres Unternehmens, Selbstständiger usw. sind.
      - Eine Bankbescheinigung
      - Nachweis der Unterstützung durch einen Dritten
      - Nachweis über ausreichende Ersparnisse
    - Nachweis der Unbescholtenheit, wie:
      - Ein Auszug aus Ihrem Strafregister
      - Eine eidesstattliche Erklärung, dass Sie noch nie verurteilt wurden.
    - Ausweisdokumente
    - Das Antragsformular für ein Langzeitvisum

    Sobald Sie das Visum erhalten haben, müssen Sie die offizielle Aufenthaltserlaubnis bei der öffentlichen Sicherheitsbehörde beantragen und dabei dasselbe Verfahren wie europäische Staatsangehörige befolgen.

    Falls Sie sich jedoch vor Ihrem Umzug nach Monaco in Frankreich aufgehalten haben, ist das Verfahren leicht abweichend.

    ### Antragsteller, die seit mehr als einem Jahr in Frankreich leben

    Wenn Sie Staatsangehöriger eines Nicht-EWR-Staates sind und seit mehr als einem Jahr in Frankreich wohnen, müssen Sie Folgendes tun:

    - Den Niederlassungsantrag bei der französischen Botschaft in Monaco einreichen.
    - Eine Kopie der französischen Aufenthaltserlaubnis vorlegen

    ### Antragsteller, die seit weniger als einem Jahr in Frankreich leben

    Als nicht-europäischer Staatsangehöriger, der seit weniger als einem Jahr in Frankreich lebt, müssen Sie die für Ausländer aus Staaten außerhalb des Europäischen Wirtschaftsraums geltenden Regeln befolgen und Ihren Visumantrag beim französischen Konsulat einreichen.

    Insgesamt ist das formelle Antragsverfahren angenehm unkompliziert und vor allem lohnenswert! Das Fürstentum bietet die Vorteile eines unvergleichlichen Steuersystems, einen außergewöhnlich hohen Lebensstandard, das prestigeträchtigste Umfeld, das man sich wünschen kann, und visumfreien Zugang zu allen Schengen-Staaten für seine Einwohner.
  BODY
  "sv" => <<~BODY,
    Att bosätta sig i Furstendömet som utlandssvensk eller för att bli permanent bosatt kräver en grundlig kunskap om förfarandet och de villkor som måste uppfyllas. I denna artikel hittar du all viktig information du behöver känna till för att bosätta dig i Monaco.

    ### Vistas i Monaco i mindre än 3 månader

    Utlänningar som planerar att vistas i Monaco i högst tre månader per år behöver i allmänhet bara ett identitetshandling, såsom ett identitetskort eller ett pass. För icke-européer krävs samma dokument som behövs för inresa till Frankrike.

    ### Vistas i Monaco i mer än 3 månader

    #### Krav för européer:

    För europeiska medborgare, med undantag av franska invånare som planerar att vistas mer än tre månader i Furstendömet, krävs följande bevis för att erhålla ett officiellt uppehållstillstånd från den offentliga säkerhetsmyndigheten:

    - Bevis på bostad i Monaco (den kan hyras eller ägas).
    - Bevis på tillräckliga ekonomiska resurser såsom:
      - Ett anställningsavtal
      - Ett auktoriserat dokument som anger att du är företagsledare, egenföretagare osv.
      - Ett bankintyg
      - Bevis på stöd från en tredje part
      - Bevis på tillräckligt sparande
    - Bevis på god vandel, såsom:
      - Ett utdrag ur brottsregistret
      - Ett hedersintyg som intygar att du aldrig har dömts tidigare.

    Europeiska invånare behöver inte ansöka om visum för att bosätta sig i Monaco.

    #### Krav för icke-européer:

    Om du är medborgare i en stat som inte ingår i Europeiska ekonomiska samarbetsområdet måste du ansöka om visum för att komma till Monaco genom att lämna in följande handlingar till det franska konsulatet:

    - Bevis på bostad i Monaco (den kan hyras, ägas eller utlovas).
    - Bevis på tillräckliga ekonomiska resurser såsom:
      - Ett anställningsavtal
      - Ett auktoriserat dokument som anger att du är företagsledare, egenföretagare osv.
      - Ett bankintyg
      - Bevis på stöd från en tredje part
      - Bevis på tillräckligt sparande
    - Bevis på god vandel, såsom:
      - Ett utdrag ur brottsregistret
      - Ett hedersintyg som intygar att du aldrig har dömts tidigare.
    - Identitetshandlingar
    - Ansökningsformuläret för visum för längre vistelse

    Så snart du har fått visumet måste du ansöka om det officiella uppehållstillståndet hos den offentliga säkerhetsmyndigheten, enligt samma förfarande som för europeiska medborgare.

    Om du dock har vistats i Frankrike före din flytt till Monaco är förfarandet något annorlunda.

    ### Sökande som har vistats i Frankrike i mer än ett år

    Om du är medborgare i en stat utanför Europeiska ekonomiska samarbetsområdet och har bott i Frankrike i mer än ett år, är detta vad du behöver göra:

    - Lämna in bosättningsansökan till franska ambassaden i Monaco.
    - Uppvisa en kopia av det franska uppehållstillståndet

    ### Sökande som har vistats i Frankrike i mindre än ett år

    Som icke-europeisk medborgare som vistats i Frankrike i mindre än ett år måste du följa de regler som gäller för utlänningar från stater utanför Europeiska ekonomiska samarbetsområdet och lämna in din visumansökan till det franska konsulatet.

    Sammantaget är det formella ansökningsförfarandet angenämt enkelt och framför allt väl värt besväret! Furstendömet erbjuder fördelarna med ett oöverträffat skattesystem, en exceptionellt hög levnadsstandard, den mest prestigefyllda miljön du kan önska dig och visumfri tillgång till alla Schengenländer för sina invånare.
  BODY
  "no" => <<~BODY,
    Å bosette seg i Fyrstedømmet som utlending eller for å bli fast bosatt krever en grundig kjennskap til prosedyren som skal følges og vilkårene som må oppfylles. I denne artikkelen finner du all viktig informasjon du trenger å vite for å bosette deg i Monaco.

    ### Opphold i Monaco i mindre enn 3 måneder

    Utlendinger som planlegger å oppholde seg i Monaco i maksimalt tre måneder per år trenger vanligvis bare et identitetsdokument, for eksempel et identitetskort eller et reisepass. For ikke-europeere kreves det samme dokumentet som for innreise til Frankrike.

    ### Opphold i Monaco i mer enn 3 måneder

    #### Krav for europeere:

    For europeiske statsborgere, med unntak av franske innbyggere som planlegger å oppholde seg mer enn tre måneder i Fyrstedømmet, kreves følgende dokumentasjon for å få en offisiell oppholdstillatelse fra offentlig sikkerhetstjeneste:

    - Bevis på bolig i Monaco (den kan leies eller eies).
    - Bevis på tilstrekkelige økonomiske ressurser som:
      - En arbeidskontrakt
      - Et autorisert dokument som angir at du er bedriftsleder, selvstendig næringsdrivende osv.
      - En bankattest
      - Bevis på støtte fra en tredjepart
      - Bevis på tilstrekkelige sparemidler
    - Bevis på god vandel, som:
      - Et utdrag fra strafferegisteret
      - En æreserklæring som bekrefter at du aldri har vært domfelt.

    Europeiske innbyggere trenger ikke å søke om visum for å bosette seg i Monaco.

    #### Krav for ikke-europeere:

    Hvis du er statsborger i en stat som ikke er en del av Det europeiske økonomiske samarbeidsområdet, må du søke om visum for å komme til Monaco ved å sende inn følgende dokumenter til det franske konsulatet:

    - Bevis på bolig i Monaco (den kan leies, eies eller være lovet).
    - Bevis på tilstrekkelige økonomiske ressurser som:
      - En arbeidskontrakt
      - Et autorisert dokument som angir at du er bedriftsleder, selvstendig næringsdrivende osv.
      - En bankattest
      - Bevis på støtte fra en tredjepart
      - Bevis på tilstrekkelige sparemidler
    - Bevis på god vandel, som:
      - Et utdrag fra strafferegisteret
      - En æreserklæring som bekrefter at du aldri har vært domfelt.
    - Identitetsdokumenter
    - Søknadsskjemaet for visum for lengre opphold

    Så snart du har fått visumet, må du søke om den offisielle oppholdstillatelsen hos offentlig sikkerhetstjeneste, etter samme prosedyre som europeiske statsborgere.

    Hvis du imidlertid har oppholdt deg i Frankrike før flyttingen til Monaco, er prosedyren noe annerledes.

    ### Søkere som har oppholdt seg i Frankrike i mer enn ett år

    Hvis du er statsborger i en stat utenfor Det europeiske økonomiske samarbeidsområdet og har bodd i Frankrike i mer enn ett år, er dette hva du må gjøre:

    - Sende inn bosettingssøknaden til den franske ambassaden i Monaco.
    - Fremlegge en kopi av den franske oppholdstillatelsen

    ### Søkere som har oppholdt seg i Frankrike i mindre enn ett år

    Som ikke-europeisk statsborger med opphold i Frankrike i mindre enn ett år, må du følge reglene som gjelder for utlendinger fra stater utenfor Det europeiske økonomiske samarbeidsområdet og sende inn visumsøknaden til det franske konsulatet.

    Alt i alt er den formelle søknadsprosedyren behagelig enkel og fremfor alt vel verdt det! Fyrstedømmet tilbyr fordelene med et uforlignelig skattesystem, en eksepsjonelt høy levestandard, det mest prestisjefylte miljøet du kan ønske deg, og visumfri tilgang til alle Schengen-stater for sine innbyggere.
  BODY
  "da" => <<~BODY,
    At bosætte sig i Fyrstendømmet som udlænding eller for at blive fastboende kræver et indgående kendskab til proceduren og de betingelser, der skal opfyldes. I denne artikel finder du alle de vigtige oplysninger, du har brug for at kende, for at bosætte dig i Monaco.

    ### Ophold i Monaco i mindre end 3 måneder

    Udlændinge, der planlægger at opholde sig i Monaco i højst tre måneder om året, har generelt kun brug for et identitetsdokument, såsom et identitetskort eller et rejsepas. For ikke-europæere kræves det samme dokument som for indrejse til Frankrig.

    ### Ophold i Monaco i mere end 3 måneder

    #### Krav for europæere:

    For europæiske statsborgere, med undtagelse af franske indbyggere der planlægger at opholde sig mere end tre måneder i Fyrstendømmet, kræves følgende dokumentation for at opnå en officiel opholdstilladelse fra den offentlige sikkerhedstjeneste:

    - Bevis for bolig i Monaco (den kan lejes eller ejes).
    - Bevis for tilstrækkelige økonomiske ressourcer såsom:
      - En ansættelseskontrakt
      - Et autoriseret dokument, der angiver, at du er virksomhedsleder, selvstændig osv.
      - En bankattest
      - Bevis for støtte fra en tredjepart
      - Bevis for tilstrækkelig opsparing
    - Bevis for god vandel, såsom:
      - En udskrift fra strafferegisteret
      - En æreserklæring, der bekræfter, at du aldrig er blevet dømt.

    Europæiske indbyggere behøver ikke ansøge om visum for at bosætte sig i Monaco.

    #### Krav for ikke-europæere:

    Hvis du er statsborger i en stat, der ikke er en del af Det Europæiske Økonomiske Samarbejdsområde, skal du ansøge om visum for at komme til Monaco ved at indsende følgende dokumenter til det franske konsulat:

    - Bevis for bolig i Monaco (den kan lejes, ejes eller være lovet).
    - Bevis for tilstrækkelige økonomiske ressourcer såsom:
      - En ansættelseskontrakt
      - Et autoriseret dokument, der angiver, at du er virksomhedsleder, selvstændig osv.
      - En bankattest
      - Bevis for støtte fra en tredjepart
      - Bevis for tilstrækkelig opsparing
    - Bevis for god vandel, såsom:
      - En udskrift fra strafferegisteret
      - En æreserklæring, der bekræfter, at du aldrig er blevet dømt.
    - Identitetsdokumenter
    - Ansøgningsformularen for visum til længerevarende ophold

    Så snart du har fået visumet, skal du ansøge om den officielle opholdstilladelse hos den offentlige sikkerhedstjeneste efter samme procedure som europæiske statsborgere.

    Hvis du imidlertid har opholdt dig i Frankrig før din flytning til Monaco, er proceduren lidt anderledes.

    ### Ansøgere, der har opholdt sig i Frankrig i mere end et år

    Hvis du er statsborger i en stat uden for Det Europæiske Økonomiske Samarbejdsområde og har boet i Frankrig i mere end et år, er her hvad du skal gøre:

    - Indsende bosættelsesansøgningen til den franske ambassade i Monaco.
    - Fremvise en kopi af den franske opholdstilladelse

    ### Ansøgere, der har opholdt sig i Frankrig i mindre end et år

    Som ikke-europæisk statsborger med ophold i Frankrig i mindre end et år skal du følge de regler, der gælder for udlændinge fra stater uden for Det Europæiske Økonomiske Samarbejdsområde, og indsende din visumansøgning til det franske konsulat.

    Alt i alt er den formelle ansøgningsprocedure behageligt enkel og frem for alt det hele værd! Fyrstendømmet tilbyder fordelene ved et uforlignelig skattesystem, en usædvanligt høj levestandard, det mest prestigefyldte miljø, du kan ønske dig, og visumfri adgang til alle Schengen-stater for sine indbyggere.
  BODY
  "fi" => <<~BODY
    Ruhtinaskuntaan asettuminen ulkomaalaisena tai pysyväksi asukkaaksi tuleminen edellyttää perusteellista tietoa noudatettavasta menettelystä ja täytettävistä ehdoista. Tässä artikkelissa löydät kaikki tärkeät tiedot, jotka sinun on tiedettävä asettuaksesi Monacoon.

    ### Oleskelu Monacossa alle 3 kuukautta

    Ulkomaalaiset, jotka suunnittelevat oleskelua Monacossa enintään kolme kuukautta vuodessa, tarvitsevat yleensä vain henkilöllisyystodistuksen, kuten henkilökortin tai passin. EU:n ulkopuolisilta kansalaisilta vaaditaan sama asiakirja kuin Ranskaan saapumiseen.

    ### Oleskelu Monacossa yli 3 kuukautta

    #### Vaatimukset eurooppalaisille:

    Eurooppalaisten kansalaisten, lukuun ottamatta Ranskassa asuvia, jotka suunnittelevat oleskelua Ruhtinaskunnassa yli kolme kuukautta, on esitettävä seuraavat todisteet saadakseen virallisen oleskeluluvan yleiseltä turvallisuusviranomaiselta:

    - Todistus asunnosta Monacossa (se voi olla vuokrattu tai omistettu).
    - Todistus riittävistä taloudellisista varoista, kuten:
      - Työsopimus
      - Valtuutettu asiakirja, joka osoittaa, että olet yrityksesi johtaja, itsenäinen ammatinharjoittaja jne.
      - Pankkitodistus
      - Todistus kolmannen osapuolen tuesta
      - Todistus riittävistä säästöistä
    - Todistus hyvästä maineesta, kuten:
      - Ote rikosrekisteristä
      - Kunniavakuutus, joka todistaa, ettei sinua ole koskaan tuomittu.

    Eurooppalaisten asukkaiden ei tarvitse hakea viisumia asettuakseen Monacoon.

    #### Vaatimukset EU:n ulkopuolisille kansalaisille:

    Jos olet sellaisen valtion kansalainen, joka ei kuulu Euroopan talousalueeseen, sinun on haettava viisumia saapuaksesi Monacoon toimittamalla seuraavat asiakirjat Ranskan konsulaattiin:

    - Todistus asunnosta Monacossa (se voi olla vuokrattu, omistettu tai luvattu).
    - Todistus riittävistä taloudellisista varoista, kuten:
      - Työsopimus
      - Valtuutettu asiakirja, joka osoittaa, että olet yrityksesi johtaja, itsenäinen ammatinharjoittaja jne.
      - Pankkitodistus
      - Todistus kolmannen osapuolen tuesta
      - Todistus riittävistä säästöistä
    - Todistus hyvästä maineesta, kuten:
      - Ote rikosrekisteristä
      - Kunniavakuutus, joka todistaa, ettei sinua ole koskaan tuomittu.
    - Henkilöllisyysasiakirjat
    - Pitkäaikaisen viisumin hakulomake

    Heti kun olet saanut viisumin, sinun on haettava virallista oleskelulupaa yleiseltä turvallisuusviranomaiselta noudattaen samaa menettelyä kuin eurooppalaiset kansalaiset.

    Jos olet kuitenkin oleskellut Ranskassa ennen muuttoasi Monacoon, menettely on hieman erilainen.

    ### Hakijat, jotka ovat oleskelleet Ranskassa yli vuoden

    Jos olet Euroopan talousalueen ulkopuolisen valtion kansalainen ja olet asunut Ranskassa yli vuoden, sinun on toimittava seuraavasti:

    - Jätä asettautumishakemus Ranskan suurlähetystöön Monacossa.
    - Esitä kopio ranskalaisesta oleskeluluvasta

    ### Hakijat, jotka ovat oleskelleet Ranskassa alle vuoden

    EU:n ulkopuolisena kansalaisena, joka on oleskellut Ranskassa alle vuoden, sinun on noudatettava Euroopan talousalueen ulkopuolisten valtioiden kansalaisiin sovellettavia sääntöjä ja jätettävä viisumihakemuksesi Ranskan konsulaattiin.

    Kaiken kaikkiaan virallinen hakumenettely on miellyttävän yksinkertainen ja ennen kaikkea sen arvoinen! Ruhtinaskunta tarjoaa vertaansa vailla olevan verojärjestelmän edut, poikkeuksellisen korkean elintason, arvostetuimman elinympäristön, jota voi toivoa, ja viisumivapaan pääsyn kaikkiin Schengen-maihin asukkailleen.
  BODY
)

article.save!
puts "OK: #{article.slug} (#{article.title.keys.sort.join(', ')})"
