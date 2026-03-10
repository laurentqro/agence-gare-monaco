# rails runner lib/tasks/translate_article_05.rb
article = Article.find_by!(slug: "notre-guide-d-achat-de-bien-immobilier-a-monaco")

article.title = article.title.merge(
  "en" => "Our guide to buying property in Monaco",
  "it" => "La nostra guida all'acquisto di immobili a Monaco",
  "de" => "Unser Leitfaden zum Immobilienkauf in Monaco",
  "sv" => "Vår guide till fastighetsköp i Monaco",
  "no" => "Vår guide til eiendomskjøp i Monaco",
  "da" => "Vores guide til ejendomskøb i Monaco",
  "fi" => "Oppaamme kiinteistön ostamiseen Monacossa"
)

article.body = article.body.merge(
  "en" => <<~BODY,
    In your search for property in Monaco, our agency is by your side to guide you in your choice. We advise you throughout the entire purchasing process.

    #### A simplified acquisition process

    Entrusting your project to our agency of experts will simplify the process of purchasing your property. You will only need to provide us with the following information:

    - your needs: rental/capital investment or intended use (residential/commercial)
    - your budget for this project
    - whether you are coming with family, alone or as a couple
    - whether you have a preferred neighbourhood
    - any information you consider necessary to allow us to best support you in your project

    Armed with all this information, we will propose properties that are publicly listed for sale, as well as those whose sale is much more confidential. This is where our added value lies as a local agency with mastery of the market. Indeed, our partners share "off-market" opportunities with us. A real estate market that is neither displayed in agency windows nor on websites dedicated to property in the Principality.

    We will visit the properties that have caught your attention with you and help you assess their true value. We will conduct negotiations with the seller on your behalf, under your control and in accordance with your price expectations.

    Once an agreement is reached, a purchase offer will be drafted by our team. On this point, we draw your attention to the fact that any acceptance of the offer countersigned by the seller constitutes a definitive commitment. Only the conditions precedent mentioned in the purchase offer could then release you from the contract.

    We ensure that this purchase offer includes all mandatory legal conditions:

    - the identity of the buyer, verified against identification documents,
    - a clear description of the property targeted by the acquisition,
    - the sale price of the property as well as the payment method you have chosen,
    - the validity period of the purchase offer,
    - the charges as well as the conditions applying to the sale,
    - the well-known conditions precedent, which may take the form of works to be carried out, or financing to be obtained, and which must be fulfilled within the specified timeframes,
    - the various fees and charges applicable to the purchase of your future property,
    - finally, the deadline by which the execution of the authentic deed must take place between the seller and yourself.

    Once the offer is duly accepted, we can deposit your deposit cheque with a notary in the Principality. You may also make a bank transfer directly to the notary's office account, within 48 hours. The purchase offer will then be accepted and neither you nor the seller may withdraw.

    #### Do I need to draft a preliminary sales agreement?

    The preliminary sales agreement is not a mandatory act in Monaco. Nevertheless, it is safer to draft one if you are purchasing your property through a bank loan or if the property may be pre-empted by the State.

    Indeed, the Principality of Monaco reserves the right to pre-empt real estate properties whose construction predates the year 1947. The administration then has a period of 30 days from the signing of the preliminary agreement to substitute itself for you in the property acquisition process.

    #### How does the handover of keys work?

    The signing of the authentic deed takes place at a notary's office in the Principality. A key moment of your purchase, your signature on the deed gives it the force of res judicata.

    Its date marks the beginning of your new status as property owner. It is at this moment that the keys are handed over to you. But first, you must settle the notarial fees related to the property acquisition:

    - The purchase of a new property or one under future completion requires payment of fees amounting to 2.5% of the total value of the property.
    - In the case where you purchase the property as a natural person, or through a civil company registered in the Principality, the fees are set at 6% of the property value.
    - A purchase made on behalf of an offshore or foreign company gives rise to fees amounting to 7.5% of the total value of the property.
    - Finally, life annuity sales are subject to fees amounting to 6% of the estimated value of the lump sum plus the sum of 10 years of annuity payments.

    In addition, agency fees are set by the schedule of the Monaco Real Estate Chamber at 3% excluding tax for buyers on the purchase price; which must be settled at the latest at the time of signing the authentic deed.

    You are now in possession of the keys to your new property. If it is a property dedicated to rental, we can also assist you with the rental management of your property.

    **Sources:**

    - https://service-public-particuliers.gouv.mc
    - Loi n. 1.381 du 29/06/2011, relative aux droits d'enregistrement exigibles sur les mutations de biens et de droits immobiliers, section II, Des droits d'enregistrement et d'hypothèque.
    - Ordonnance n. 1.016 du 04/11/1954, fixant les modalités d'exercice du droit de préemption insitué par l'article 28 de la loi n°580, du 29 juillet 1953.
    - https://www.legimonaco.mc
  BODY
  "it" => <<~BODY,
    Nella ricerca del vostro immobile a Monaco, la nostra agenzia è al vostro fianco per accompagnarvi nella scelta. Vi consigliamo durante l'intero processo di acquisto.

    #### Un processo di acquisizione semplificato

    Affidare il vostro progetto alla nostra agenzia di esperti semplificherà il processo di acquisto del vostro immobile. Dovrete solo indicarci i seguenti elementi:

    - le vostre esigenze: investimento locativo/patrimoniale o destinazione d'uso (residenziale/commerciale)
    - il vostro budget per questo progetto
    - se venite in famiglia, da soli o in coppia
    - se avete un quartiere preferito
    - qualsiasi informazione riteniate necessaria per permetterci di accompagnarvi al meglio nel vostro progetto

    Muniti di tutte queste informazioni, vi proporremo gli immobili oggetto di vendita pubblica, e anche quelli la cui vendita è molto più riservata. È qui che risiede tutto il nostro valore aggiunto come agenzia locale con una padronanza del mercato. Infatti, i nostri partner ci comunicano le offerte "off-market". Un mercato immobiliare che non viene esposto né nelle vetrine delle agenzie né sui siti internet dedicati all'immobiliare del Principato.

    Ci occuperemo di visitare con voi gli immobili che avranno attirato la vostra attenzione e vi aiuteremo a valutare il loro reale valore. Condurremo per voi le trattative con il venditore, sotto il vostro controllo e secondo le vostre aspettative in termini di prezzo.

    Non appena verrà raggiunto un accordo, un'offerta di acquisto verrà redatta dal nostro team. Su questo punto, attiriamo la vostra attenzione sul fatto che qualsiasi accettazione dell'offerta controfirmata dal venditore vale come impegno definitivo. Solo le condizioni sospensive menzionate nell'offerta di acquisto potrebbero allora liberarvi dal contratto.

    Ci assicuriamo che in questa offerta di acquisto figurino tutte le condizioni legali obbligatorie:

    - l'identità dell'acquirente, verificata su documento,
    - la designazione chiara dell'immobile oggetto dell'acquisizione,
    - il prezzo di vendita dell'immobile nonché la modalità di pagamento che avete scelto,
    - la durata di validità dell'offerta di acquisto,
    - gli oneri e le condizioni applicabili alla vendita,
    - le famose condizioni sospensive, che possono concretizzarsi in lavori da realizzare, o in un finanziamento da ottenere, e che devono essere soddisfatte nei termini previsti,
    - le diverse spese e onorari applicabili all'acquisto del vostro futuro immobile,
    - infine, la data limite entro la quale la ripetizione dell'atto autentico dovrà avere luogo tra il venditore e voi stessi.

    Una volta l'offerta debitamente accettata, possiamo depositare il vostro assegno di acconto presso un notaio del Principato. Potete anche procedere con un bonifico bancario direttamente sul conto dello studio, entro 48 ore. L'offerta di acquisto sarà allora accettata e, né voi né il venditore, potrete più ritirarvi.

    #### Devo redigere un compromesso di vendita?

    Il compromesso di vendita non è un atto obbligatorio a Monaco. Tuttavia, è più sicuro redigerne uno se acquistate il vostro immobile tramite un prestito bancario o se il bene può essere oggetto di prelazione da parte dello Stato.

    Infatti, il Principato di Monaco si riserva il diritto di esercitare il diritto di prelazione sugli immobili la cui costruzione è anteriore all'anno 1947. L'amministrazione dispone allora di un termine di 30 giorni a decorrere dalla firma del compromesso per sostituirsi a voi nella procedura di acquisizione dell'immobile.

    #### Come avviene la consegna delle chiavi?

    La firma dell'atto autentico si svolge presso lo studio di un notaio del Principato. Momento forte del vostro acquisto, la vostra firma sull'atto gli conferisce forza di cosa giudicata.

    La sua data segna l'inizio del vostro nuovo status di proprietario dell'immobile. È in questo momento che le chiavi vi vengono consegnate. Ma prima, dovete saldare le spese notarili relative all'acquisizione dell'immobile:

    - L'acquisto di un immobile nuovo o in stato futuro di completamento richiede il pagamento di spese pari al 2,5% del valore totale dell'immobile.
    - Nel caso in cui acquistiate l'immobile in qualità di persona fisica, o tramite una società civile registrata nel Principato, le spese sono fissate al 6% del valore dell'immobile.
    - L'acquisto effettuato per conto di una società offshore o straniera dà luogo a spese pari al 7,5% del valore totale dell'immobile.
    - Infine, le vendite con vitalizio sono soggette a spese pari al 6% del valore stimato del capitale iniziale più la somma di 10 anni di rendita.

    Inoltre, gli onorari d'agenzia sono fissati dal tariffario della Camera Immobiliare Monegasca al 3% escluse le tasse per gli acquirenti sul prezzo di acquisto; che dovranno essere saldati al più tardi al momento della firma dell'atto autentico.

    Siete ora in possesso delle chiavi del vostro nuovo immobile. Se si tratta di un immobile destinato alla locazione, possiamo inoltre accompagnarvi nella gestione locativa del vostro bene.

    **Fonti:**

    - https://service-public-particuliers.gouv.mc
    - Loi n. 1.381 du 29/06/2011, relative aux droits d'enregistrement exigibles sur les mutations de biens et de droits immobiliers, section II, Des droits d'enregistrement et d'hypothèque.
    - Ordonnance n. 1.016 du 04/11/1954, fixant les modalités d'exercice du droit de préemption insitué par l'article 28 de la loi n°580, du 29 juillet 1953.
    - https://www.legimonaco.mc
  BODY
  "de" => <<~BODY,
    Bei der Suche nach Ihrer Immobilie in Monaco steht Ihnen unsere Agentur zur Seite, um Sie bei Ihrer Wahl zu begleiten. Wir beraten Sie während des gesamten Kaufprozesses.

    #### Ein vereinfachter Erwerbsprozess

    Wenn Sie Ihr Projekt unserer Expertenagentur anvertrauen, wird der Kaufprozess Ihrer Immobilie vereinfacht. Sie müssen uns lediglich folgende Informationen mitteilen:

    - Ihre Bedürfnisse: Miet-/Vermögensinvestition oder Nutzungszweck (Wohn-/Geschäftsnutzung)
    - Ihr Budget für dieses Projekt
    - ob Sie mit Familie, allein oder zu zweit kommen
    - ob Sie ein bevorzugtes Viertel haben
    - alle Informationen, die Sie für notwendig erachten, damit wir Sie bestmöglich bei Ihrem Projekt begleiten können

    Mit all diesen Informationen ausgestattet, werden wir Ihnen Immobilien vorschlagen, die öffentlich zum Verkauf stehen, sowie solche, deren Verkauf weitaus vertraulicher ist. Darin liegt unser gesamter Mehrwert als lokale Agentur mit Marktkenntnis. Tatsächlich teilen uns unsere Partner die "Off-Market"-Angebote mit. Ein Immobilienmarkt, der weder in den Schaufenstern der Agenturen noch auf den Immobilien-Websites des Fürstentums zu finden ist.

    Wir werden die Immobilien, die Ihre Aufmerksamkeit erregt haben, gemeinsam mit Ihnen besichtigen und Ihnen helfen, ihren tatsächlichen Wert einzuschätzen. Wir führen die Verhandlungen mit dem Verkäufer in Ihrem Namen, unter Ihrer Kontrolle und gemäß Ihren Preisvorstellungen.

    Sobald eine Einigung erzielt wird, wird ein Kaufangebot von unserem Team erstellt. An dieser Stelle möchten wir Sie darauf aufmerksam machen, dass jede Annahme des vom Verkäufer gegengezeichneten Angebots eine endgültige Verpflichtung darstellt. Nur die im Kaufangebot genannten aufschiebenden Bedingungen könnten Sie dann vom Vertrag lösen.

    Wir stellen sicher, dass dieses Kaufangebot alle gesetzlich vorgeschriebenen Bedingungen enthält:

    - die Identität des Käufers, durch Dokumente überprüft,
    - die eindeutige Bezeichnung der zu erwerbenden Immobilie,
    - den Verkaufspreis der Immobilie sowie die von Ihnen gewählte Zahlungsart,
    - die Gültigkeitsdauer des Kaufangebots,
    - die Kosten sowie die für den Verkauf geltenden Bedingungen,
    - die bekannten aufschiebenden Bedingungen, die sich in durchzuführenden Arbeiten oder zu beschaffender Finanzierung materialisieren können und die innerhalb der vorgesehenen Fristen erfüllt werden müssen,
    - die verschiedenen Gebühren und Honorare, die beim Kauf Ihrer zukünftigen Immobilie anfallen,
    - schließlich das Datum, bis zu dem die Beurkundung zwischen dem Verkäufer und Ihnen erfolgen muss.

    Sobald das Angebot ordnungsgemäß angenommen wurde, können wir Ihren Anzahlungsscheck bei einem Notar des Fürstentums hinterlegen. Sie können auch eine Banküberweisung direkt auf das Konto der Kanzlei vornehmen, innerhalb von 48 Stunden. Das Kaufangebot ist dann angenommen und weder Sie noch der Verkäufer können mehr zurücktreten.

    #### Muss ich einen Vorvertrag erstellen?

    Der Vorvertrag ist in Monaco kein obligatorischer Akt. Dennoch ist es sicherer, einen zu erstellen, wenn Sie Ihre Immobilie über ein Bankdarlehen kaufen oder wenn die Immobilie vom Staat vorkaufsrechtlich beansprucht werden kann.

    Tatsächlich behält sich das Fürstentum Monaco das Recht vor, Immobilien, deren Bau vor dem Jahr 1947 liegt, durch Vorkaufsrecht zu erwerben. Die Verwaltung verfügt dann über eine Frist von 30 Tagen ab Unterzeichnung des Vorvertrags, um sich im Erwerbsverfahren an Ihre Stelle zu setzen.

    #### Wie erfolgt die Schlüsselübergabe?

    Die Unterzeichnung der notariellen Urkunde findet in einer Notarkanzlei des Fürstentums statt. Als wichtiger Moment Ihres Kaufs verleiht Ihre Unterschrift auf der Urkunde dieser Rechtskraft.

    Ihr Datum markiert den Beginn Ihres neuen Status als Immobilieneigentümer. In diesem Moment werden Ihnen die Schlüssel übergeben. Zuvor müssen Sie jedoch die mit dem Immobilienerwerb verbundenen Notargebühren begleichen:

    - Der Kauf einer Neuimmobilie oder einer Immobilie im zukünftigen Fertigstellungszustand erfordert die Zahlung von Gebühren in Höhe von 2,5% des Gesamtwerts der Immobilie.
    - Falls Sie die Immobilie als natürliche Person oder über eine im Fürstentum eingetragene Zivilgesellschaft erwerben, betragen die Gebühren 6% des Immobilienwerts.
    - Ein Kauf im Namen einer Offshore- oder ausländischen Gesellschaft führt zu Gebühren in Höhe von 7,5% des Gesamtwerts der Immobilie.
    - Schließlich unterliegen Leibrentenverkäufe Gebühren in Höhe von 6% des geschätzten Werts der Einmalzahlung zuzüglich der Summe von 10 Jahresrenten.

    Darüber hinaus werden die Agenturgebühren durch den Tarif der Monegassischen Immobilienkammer auf 3% zuzüglich Steuern für Käufer auf den Kaufpreis festgelegt; diese müssen spätestens zum Zeitpunkt der Unterzeichnung der notariellen Urkunde beglichen werden.

    Sie sind nun im Besitz der Schlüssel Ihrer neuen Immobilie. Wenn es sich um eine zur Vermietung bestimmte Immobilie handelt, können wir Sie darüber hinaus bei der Mietverwaltung Ihrer Immobilie unterstützen.

    **Quellen:**

    - https://service-public-particuliers.gouv.mc
    - Loi n. 1.381 du 29/06/2011, relative aux droits d'enregistrement exigibles sur les mutations de biens et de droits immobiliers, section II, Des droits d'enregistrement et d'hypothèque.
    - Ordonnance n. 1.016 du 04/11/1954, fixant les modalités d'exercice du droit de préemption insitué par l'article 28 de la loi n°580, du 29 juillet 1953.
    - https://www.legimonaco.mc
  BODY
  "sv" => <<~BODY,
    I er sökning efter fastighet i Monaco står vår byrå vid er sida för att vägleda er i ert val. Vi ger er råd genom hela köpprocessen.

    #### En förenklad förvärvsprocess

    Att anförtro ert projekt till vår expertbyrå kommer att förenkla processen att köpa er fastighet. Ni behöver bara ge oss följande information:

    - era behov: hyres-/kapitalinvestering eller användningsområde (bostad/kommersiellt)
    - er budget för detta projekt
    - om ni kommer med familj, ensamma eller som par
    - om ni har ett föredraget kvarter
    - all information ni anser nödvändig för att vi ska kunna stödja er på bästa sätt i ert projekt

    Med all denna information kommer vi att föreslå fastigheter som är offentligt till salu, samt de vars försäljning är mycket mer konfidentiell. Det är här vårt mervärde ligger som lokal byrå med marknadskännedom. Våra partners delar nämligen "off-market"-erbjudanden med oss. En fastighetsmarknad som varken visas i byråernas skyltfönster eller på webbplatser dedikerade till fastigheter i Furstendömet.

    Vi kommer att besöka de fastigheter som har fångat er uppmärksamhet tillsammans med er och hjälpa er att bedöma deras verkliga värde. Vi kommer att föra förhandlingar med säljaren å era vägnar, under er kontroll och i enlighet med era prisförväntningar.

    Så snart en överenskommelse nås kommer ett köpanbud att utarbetas av vårt team. På denna punkt vill vi uppmärksamma er på att varje godkännande av anbudet kontrasignerat av säljaren utgör ett definitivt åtagande. Endast de uppskjutande villkor som nämns i köpanbudet kan då befria er från kontraktet.

    Vi säkerställer att detta köpanbud innehåller alla obligatoriska juridiska villkor:

    - köparens identitet, verifierad mot identitetshandlingar,
    - en tydlig beskrivning av den fastighet som förvärvet avser,
    - försäljningspriset för fastigheten samt den betalningsmetod ni har valt,
    - köpanbudets giltighetstid,
    - avgifter samt villkor som gäller för försäljningen,
    - de välkända uppskjutande villkoren, som kan ta formen av arbeten som ska utföras, eller finansiering som ska erhållas, och som måste uppfyllas inom de angivna tidsfristerna,
    - de olika avgifter och arvoden som gäller vid köpet av er framtida fastighet,
    - slutligen det senaste datum då den formella akten måste undertecknas mellan säljaren och er själva.

    När anbudet vederbörligen accepterats kan vi deponera er handpenningscheck hos en notarie i Furstendömet. Ni kan också göra en banköverföring direkt till notariekontorets konto, inom 48 timmar. Köpanbudet är då accepterat och varken ni eller säljaren kan längre dra er ur.

    #### Behöver jag upprätta ett förköpsavtal?

    Förköpsavtalet är inte en obligatorisk handling i Monaco. Dock är det säkrare att upprätta ett om ni köper er fastighet genom ett banklån eller om fastigheten kan bli föremål för statlig förköpsrätt.

    Furstendömet Monaco förbehåller sig nämligen rätten att utöva förköpsrätt på fastigheter vars konstruktion är äldre än år 1947. Förvaltningen har då en frist på 30 dagar från undertecknandet av förköpsavtalet att träda i ert ställe i förvärvsförfarandet.

    #### Hur går nyckelöverlämnandet till?

    Undertecknandet av den formella akten sker vid en notariebyrå i Furstendömet. Som en viktig stund i ert köp ger er underskrift på akten den rättskraft.

    Dess datum markerar början på er nya status som fastighetsägare. Det är i detta ögonblick som nycklarna överlämnas till er. Men först måste ni betala de notarieavgifter som är kopplade till fastighetsförvärvet:

    - Köp av en ny fastighet eller en under framtida färdigställande kräver betalning av avgifter uppgående till 2,5% av fastighetens totala värde.
    - Om ni köper fastigheten som fysisk person, eller genom ett civilrättsligt bolag registrerat i Furstendömet, uppgår avgifterna till 6% av fastighetens värde.
    - Ett köp gjort för ett offshore- eller utländskt bolags räkning medför avgifter uppgående till 7,5% av fastighetens totala värde.
    - Slutligen är livränteförsäljningar föremål för avgifter uppgående till 6% av det uppskattade värdet av engångsbeloppet plus summan av 10 års livränta.

    Dessutom fastställs byråavgifterna av den Monegaskiska Fastighetskammarens tariff till 3% exklusive moms för köpare på köpeskillingen; dessa måste betalas senast vid undertecknandet av den formella akten.

    Ni är nu i besittning av nycklarna till er nya fastighet. Om det är en fastighet avsedd för uthyrning kan vi dessutom hjälpa er med hyresförvaltningen av er fastighet.

    **Källor:**

    - https://service-public-particuliers.gouv.mc
    - Loi n. 1.381 du 29/06/2011, relative aux droits d'enregistrement exigibles sur les mutations de biens et de droits immobiliers, section II, Des droits d'enregistrement et d'hypothèque.
    - Ordonnance n. 1.016 du 04/11/1954, fixant les modalités d'exercice du droit de préemption insitué par l'article 28 de la loi n°580, du 29 juillet 1953.
    - https://www.legimonaco.mc
  BODY
  "no" => <<~BODY,
    I søket etter eiendom i Monaco står vårt byrå ved din side for å veilede deg i ditt valg. Vi gir deg råd gjennom hele kjøpsprosessen.

    #### En forenklet anskaffelsesprosess

    Å overlate prosjektet ditt til vårt ekspertbyrå vil forenkle prosessen med å kjøpe eiendommen din. Du trenger bare å gi oss følgende informasjon:

    - dine behov: utleie-/kapitalinvestering eller bruksformål (bolig/næring)
    - ditt budsjett for dette prosjektet
    - om du kommer med familie, alene eller som par
    - om du har et foretrukket nabolag
    - all informasjon du anser som nødvendig for at vi best kan støtte deg i prosjektet ditt

    Med all denne informasjonen vil vi foreslå eiendommer som er offentlig lagt ut for salg, samt de hvor salget er langt mer konfidensielt. Det er her vår merverdi ligger som lokalt byrå med markedskunnskap. Våre partnere deler nemlig "off-market"-tilbud med oss. Et eiendomsmarked som verken vises i byråenes vinduer eller på nettsteder dedikert til eiendom i Fyrstedømmet.

    Vi vil besøke eiendommene som har fanget din oppmerksomhet sammen med deg og hjelpe deg å vurdere deres virkelige verdi. Vi vil føre forhandlinger med selgeren på dine vegne, under din kontroll og i samsvar med dine prisforventninger.

    Så snart en avtale er nådd, vil et kjøpstilbud bli utarbeidet av vårt team. På dette punktet gjør vi deg oppmerksom på at enhver aksept av tilbudet kontrasignert av selgeren utgjør en endelig forpliktelse. Kun de suspensive vilkårene nevnt i kjøpstilbudet kan da fri deg fra kontrakten.

    Vi sørger for at dette kjøpstilbudet inneholder alle obligatoriske juridiske vilkår:

    - kjøperens identitet, verifisert mot identitetsdokumenter,
    - en klar beskrivelse av eiendommen som er gjenstand for ervervet,
    - salgsprisen for eiendommen samt betalingsmetoden du har valgt,
    - gyldighetsperioden for kjøpstilbudet,
    - kostnader samt vilkår som gjelder for salget,
    - de velkjente suspensive vilkårene, som kan ta form av arbeider som skal utføres, eller finansiering som skal oppnås, og som må oppfylles innen de angitte fristene,
    - de ulike gebyrene og honorarene som gjelder ved kjøpet av din fremtidige eiendom,
    - til slutt fristen for når den formelle akten må undertegnes mellom selgeren og deg selv.

    Når tilbudet er behørig akseptert, kan vi deponere din depositumssjekk hos en notar i Fyrstedømmet. Du kan også foreta en bankoverføring direkte til notarkontorets konto, innen 48 timer. Kjøpstilbudet er da akseptert og verken du eller selgeren kan lenger trekke dere.

    #### Må jeg utarbeide en forhåndsavtale?

    Forhåndsavtalen er ikke en obligatorisk handling i Monaco. Likevel er det tryggere å utarbeide en hvis du kjøper eiendommen din gjennom et banklån eller hvis eiendommen kan bli gjenstand for statlig forkjøpsrett.

    Fyrstedømmet Monaco forbeholder seg nemlig retten til å utøve forkjøpsrett på eiendommer hvis konstruksjon er eldre enn år 1947. Forvaltningen har da en frist på 30 dager fra undertegnelsen av forhåndsavtalen til å tre inn i ditt sted i eiendomsanskaffelsesprosessen.

    #### Hvordan foregår nøkkeloverlevering?

    Undertegnelsen av den formelle akten foregår ved et notarkontor i Fyrstedømmet. Som et viktig øyeblikk i kjøpet ditt gir din signatur på akten den rettskraft.

    Datoen markerer begynnelsen på din nye status som eiendomseier. Det er i dette øyeblikket nøklene overleveres til deg. Men først må du betale notargebyrene knyttet til eiendomservervet:

    - Kjøp av en ny eiendom eller en under fremtidig ferdigstillelse krever betaling av gebyrer på 2,5% av eiendommens totale verdi.
    - I tilfelle du kjøper eiendommen som fysisk person, eller gjennom et sivilt selskap registrert i Fyrstedømmet, er gebyrene satt til 6% av eiendommens verdi.
    - Et kjøp gjort på vegne av et offshore- eller utenlandsk selskap medfører gebyrer på 7,5% av eiendommens totale verdi.
    - Til slutt er livrente-salg underlagt gebyrer på 6% av den estimerte verdien av engangsbeløpet pluss summen av 10 års livrente.

    I tillegg er byrågebyrene fastsatt av den Monegaskiske Eiendomskammerets tariff til 3% eksklusiv mva for kjøpere på kjøpesummen; disse må betales senest ved undertegnelsen av den formelle akten.

    Du er nå i besittelse av nøklene til din nye eiendom. Hvis det er en eiendom beregnet på utleie, kan vi dessuten bistå deg med utleieforvaltningen av eiendommen din.

    **Kilder:**

    - https://service-public-particuliers.gouv.mc
    - Loi n. 1.381 du 29/06/2011, relative aux droits d'enregistrement exigibles sur les mutations de biens et de droits immobiliers, section II, Des droits d'enregistrement et d'hypothèque.
    - Ordonnance n. 1.016 du 04/11/1954, fixant les modalités d'exercice du droit de préemption insitué par l'article 28 de la loi n°580, du 29 juillet 1953.
    - https://www.legimonaco.mc
  BODY
  "da" => <<~BODY,
    I din søgen efter ejendom i Monaco står vores bureau ved din side for at vejlede dig i dit valg. Vi rådgiver dig gennem hele købsprocessen.

    #### En forenklet erhvervelsesproces

    At betro dit projekt til vores ekspertbureau vil forenkle processen med at købe din ejendom. Du skal blot give os følgende oplysninger:

    - dine behov: udlejnings-/kapitalinvestering eller anvendelsesformål (bolig/erhverv)
    - dit budget for dette projekt
    - om du kommer med familie, alene eller som par
    - om du har et foretrukket kvarter
    - enhver information du anser for nødvendig, så vi bedst muligt kan støtte dig i dit projekt

    Med alle disse oplysninger vil vi foreslå ejendomme, der er offentligt udbudt til salg, samt dem, hvis salg er langt mere fortroligt. Det er her vores merværdi ligger som lokalt bureau med markedskendskab. Vores partnere deler nemlig "off-market"-tilbud med os. Et ejendomsmarked, der hverken vises i bureauernes vinduer eller på hjemmesider dedikeret til ejendom i Fyrstendømmet.

    Vi vil besigtige de ejendomme, der har fanget din opmærksomhed, sammen med dig og hjælpe dig med at vurdere deres reelle værdi. Vi vil føre forhandlinger med sælgeren på dine vegne, under din kontrol og i overensstemmelse med dine prisforventninger.

    Så snart en aftale er nået, vil et købstilbud blive udarbejdet af vores team. På dette punkt gør vi dig opmærksom på, at enhver accept af tilbuddet kontrasigneret af sælgeren udgør en endelig forpligtelse. Kun de suspensive betingelser, der er nævnt i købstilbuddet, kan da frigøre dig fra kontrakten.

    Vi sikrer, at dette købstilbud indeholder alle obligatoriske juridiske betingelser:

    - køberens identitet, verificeret mod identitetsdokumenter,
    - en klar beskrivelse af den ejendom, der er genstand for erhvervelsen,
    - salgsprisen for ejendommen samt den betalingsmetode du har valgt,
    - købstilbuddets gyldighedsperiode,
    - afgifter samt betingelser, der gælder for salget,
    - de velkendte suspensive betingelser, som kan tage form af arbejder, der skal udføres, eller finansiering, der skal opnås, og som skal opfyldes inden for de fastsatte frister,
    - de forskellige gebyrer og honorarer, der gælder ved købet af din fremtidige ejendom,
    - endelig fristen, inden for hvilken den formelle akt skal underskrives mellem sælgeren og dig selv.

    Når tilbuddet er behørigt accepteret, kan vi deponere din udbetalingscheck hos en notar i Fyrstendømmet. Du kan også foretage en bankoverførsel direkte til notarkontorets konto inden for 48 timer. Købstilbuddet er da accepteret, og hverken du eller sælgeren kan længere trække jer.

    #### Skal jeg udarbejde en foreløbig salgsaftale?

    Den foreløbige salgsaftale er ikke en obligatorisk handling i Monaco. Ikke desto mindre er det sikrere at udarbejde en, hvis du køber din ejendom via et banklån, eller hvis ejendommen kan blive genstand for statens forkøbsret.

    Fyrstendømmet Monaco forbeholder sig nemlig retten til at udøve forkøbsret på ejendomme, hvis konstruktion er ældre end år 1947. Forvaltningen har da en frist på 30 dage fra underskrivelsen af den foreløbige aftale til at træde i dit sted i ejendomserhvervelsesprocessen.

    #### Hvordan foregår nøgleoverdragelsen?

    Underskrivelsen af den formelle akt finder sted på et notarkontor i Fyrstendømmet. Som et vigtigt øjeblik i dit køb giver din underskrift på akten den retskraft.

    Datoen markerer begyndelsen på din nye status som ejendomsejer. Det er i dette øjeblik, nøglerne overdrages til dig. Men først skal du betale notargebyrerne i forbindelse med ejendomserhvervelsen:

    - Køb af en ny ejendom eller en under fremtidig færdiggørelse kræver betaling af gebyrer på 2,5% af ejendommens samlede værdi.
    - I tilfælde af at du køber ejendommen som fysisk person, eller gennem et civilretligt selskab registreret i Fyrstendømmet, er gebyrerne fastsat til 6% af ejendommens værdi.
    - Et køb foretaget på vegne af et offshore- eller udenlandsk selskab medfører gebyrer på 7,5% af ejendommens samlede værdi.
    - Endelig er livrentesalg underlagt gebyrer på 6% af den estimerede værdi af engangsbeløbet plus summen af 10 års livrente.

    Derudover er bureaugebyrerne fastsat af den Monegaskiske Ejendomskammers tarif til 3% ekskl. moms for købere på købesummen; disse skal betales senest ved underskrivelsen af den formelle akt.

    Du er nu i besiddelse af nøglerne til din nye ejendom. Hvis det er en ejendom beregnet til udlejning, kan vi desuden hjælpe dig med udlejningsadministrationen af din ejendom.

    **Kilder:**

    - https://service-public-particuliers.gouv.mc
    - Loi n. 1.381 du 29/06/2011, relative aux droits d'enregistrement exigibles sur les mutations de biens et de droits immobiliers, section II, Des droits d'enregistrement et d'hypothèque.
    - Ordonnance n. 1.016 du 04/11/1954, fixant les modalités d'exercice du droit de préemption insitué par l'article 28 de la loi n°580, du 29 juillet 1953.
    - https://www.legimonaco.mc
  BODY
  "fi" => <<~BODY
    Kiinteistönhaussanne Monacossa toimistomme on tukenanne ohjaamassa teitä valinnassanne. Neuvomme teitä koko ostoprosessin ajan.

    #### Yksinkertaistettu hankintaprosessi

    Projektinne uskominen asiantuntijatoimistollemme yksinkertaistaa kiinteistönne ostoprosessia. Teidän tarvitsee vain antaa meille seuraavat tiedot:

    - tarpeenne: vuokra-/pääomasijoitus tai käyttötarkoitus (asuminen/liiketoiminta)
    - budjettinne tätä projektia varten
    - tuletteko perheen kanssa, yksin vai pariskuntana
    - onko teillä suosikkikaupunginosaa
    - kaikki tiedot, joita pidätte tarpeellisina, jotta voimme tukea teitä parhaalla mahdollisella tavalla projektissanne

    Näiden tietojen perusteella ehdotamme teille kiinteistöjä, jotka ovat julkisesti myynnissä, sekä niitä, joiden myynti on huomattavasti luottamuksellisempaa. Tässä piilee lisäarvomme paikallisena toimistona, jolla on markkinatuntemus. Kumppanimme jakavat meille nimittäin "off-market"-tarjouksia. Kiinteistömarkkinat, joita ei esitellä toimistojen näyteikkunoissa eikä Ruhtinaskunnan kiinteistöille omistetuilla verkkosivustoilla.

    Käymme kanssanne katsomassa kiinteistöjä, jotka ovat herättäneet huomionne, ja autamme teitä arvioimaan niiden todellisen arvon. Käymme neuvottelut myyjän kanssa puolestanne, teidän valvonnassanne ja hintaodotustenne mukaisesti.

    Heti kun sopimukseen päästään, tiimimme laatii ostotarjouksen. Tässä kohdassa kiinnitämme huomionne siihen, että myyjän allekirjoittaman tarjouksen hyväksyminen muodostaa lopullisen sitoumuksen. Vain ostotarjouksessa mainitut lykkäävät ehdot voisivat tällöin vapauttaa teidät sopimuksesta.

    Varmistamme, että tämä ostotarjous sisältää kaikki pakolliset oikeudelliset ehdot:

    - ostajan henkilöllisyys, henkilöllisyystodistuksesta varmennettu,
    - selkeä kuvaus hankittavasta kiinteistöstä,
    - kiinteistön myyntihinta sekä valitsemanne maksutapa,
    - ostotarjouksen voimassaoloaika,
    - maksut sekä myyntiin sovellettavat ehdot,
    - tunnetut lykkäävät ehdot, jotka voivat ilmetä suoritettavina töinä tai hankittavana rahoituksena ja jotka on täytettävä määrätyissä aikarajoissa,
    - erilaiset maksut ja palkkiot, jotka koskevat tulevan kiinteistönne ostoa,
    - lopuksi määräaika, johon mennessä virallinen asiakirja on allekirjoitettava myyjän ja teidän välillänne.

    Kun tarjous on asianmukaisesti hyväksytty, voimme tallettaa käsirahashekkinne Ruhtinaskunnan notaarille. Voitte myös tehdä pankkisiirron suoraan notaaritoimiston tilille 48 tunnin kuluessa. Ostotarjous on tällöin hyväksytty, eikä te eikä myyjä voi enää perääntyä.

    #### Tarvitseeko minun laatia esisopimus?

    Esisopimus ei ole pakollinen toimi Monacossa. On kuitenkin turvallisempaa laatia sellainen, jos ostatte kiinteistönne pankkilainalla tai jos kiinteistö voi olla valtion etuosto-oikeuden kohteena.

    Monacon Ruhtinaskunta pidättää nimittäin oikeuden käyttää etuosto-oikeutta kiinteistöihin, joiden rakentaminen on tapahtunut ennen vuotta 1947. Hallinnolla on tällöin 30 päivän määräaika esisopimuksen allekirjoittamisesta astuakseen teidän tilallenne kiinteistön hankintamenettelyssä.

    #### Miten avainten luovutus tapahtuu?

    Virallisen asiakirjan allekirjoitus tapahtuu Ruhtinaskunnan notaaritoimistossa. Ostonne tärkeänä hetkenä allekirjoituksenne antaa asiakirjalle lainvoiman.

    Sen päivämäärä merkitsee uuden asemanne alkua kiinteistön omistajana. Juuri tällä hetkellä avaimet luovutetaan teille. Mutta ensin teidän on maksettava kiinteistön hankintaan liittyvät notaarimaksut:

    - Uuden kiinteistön tai tulevaisuudessa valmistuvan kiinteistön osto edellyttää maksujen suorittamista, jotka ovat 2,5% kiinteistön kokonaisarvosta.
    - Mikäli ostatte kiinteistön luonnollisena henkilönä tai Ruhtinaskunnassa rekisteröidyn siviilioikeudellisen yhtiön kautta, maksut ovat 6% kiinteistön arvosta.
    - Offshore- tai ulkomaisen yhtiön puolesta tehty osto johtaa maksuihin, jotka ovat 7,5% kiinteistön kokonaisarvosta.
    - Lopuksi elinkorkomyynnit ovat 6% kertakorvauksen arvioidusta arvosta lisättynä 10 vuoden elinkoron summalla.

    Lisäksi toimistomaksut on Monacon Kiinteistökamarin tariffin mukaan asetettu 3%:iin ilman veroja ostajille ostohinnasta; ne on maksettava viimeistään virallisen asiakirjan allekirjoitushetkellä.

    Olette nyt uuden kiinteistönne avainten haltijoita. Jos kyseessä on vuokraukseen tarkoitettu kiinteistö, voimme lisäksi auttaa teitä kiinteistönne vuokrahallinnassa.

    **Lähteet:**

    - https://service-public-particuliers.gouv.mc
    - Loi n. 1.381 du 29/06/2011, relative aux droits d'enregistrement exigibles sur les mutations de biens et de droits immobiliers, section II, Des droits d'enregistrement et d'hypothèque.
    - Ordonnance n. 1.016 du 04/11/1954, fixant les modalités d'exercice du droit de préemption insitué par l'article 28 de la loi n°580, du 29 juillet 1953.
    - https://www.legimonaco.mc
  BODY
)

article.save!
puts "OK: #{article.slug} (#{article.title.keys.sort.join(', ')})"
