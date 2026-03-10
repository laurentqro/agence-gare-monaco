# rails runner lib/tasks/translate_article_04.rb
article = Article.find_by!(slug: "comment-vendre-son-bien-immobilier-a-monaco")

article.title = article.title.merge(
  "en" => "How to sell your property in Monaco?",
  "it" => "Come vendere il proprio immobile a Monaco?",
  "de" => "Wie verkaufen Sie Ihre Immobilie in Monaco?",
  "sv" => "Hur säljer du din fastighet i Monaco?",
  "no" => "Hvordan selge eiendommen din i Monaco?",
  "da" => "Hvordan sælger du din ejendom i Monaco?",
  "fi" => "Kuinka myydä kiinteistösi Monacossa?"
)

article.body = article.body.merge(
  "en" => <<~BODY,
    Our expert team supports you through all the necessary steps for the completion of your property sale in Monaco.

    ### Estimate the value of your property

    A good estimate of your property will help conclude a quick sale, as the true value of your property will attract the right buyers. To assess the real value of your property, one of our negotiators will visit your property to gather as many elements as possible to estimate the right price.

    ### We handle all the administrative aspects of the sale

    We take care of everything so that your experience is as pleasant as possible.

    We collect from you all the documents necessary for the sale of your property, namely:

    - your proof of ownership of the property to be sold,
    - a copy of your identity documents (passport and identity card and/or residence permit currently valid)
    - a copy of proof of address
    - the last three minutes of the general meeting of the co-ownership,
    - the co-ownership regulations,
    - all legal documents relating to your company, if you are selling as a legal entity,
    - the rental management file if the property you are selling is subject to a lease,
    - the as-built file for works subject to a building permit.

    Once your file is complete, our team will propose the conclusion of a sales mandate. This is a contract indicating the sale price, our remuneration, its duration and its conditions. It is a bilateral contract that commits us mutually.

    ### Everything you need to know about the sales mandate

    The sales mandate can take three forms. It can be simple, exclusive or co-exclusive:

    #### The simple sales mandate

    This type of mandate allows you to entrust the sale of your property to several real estate agencies (more legally called agents). It also leaves you the opportunity to sell your property yourself. The agent who has managed to connect you with a buyer and direct the negotiations will be the only one remunerated for their service.

    This type of mandate gives you great freedom of action, but has negative aspects. The great competition between providers reduces their chances of being remunerated. This often tends to limit the involvement of our competitors. Moreover, it is common to see the same property advertised with different information such as the sale price, the surface area... which is a serious handicap in negotiations with potential buyers.

    It is therefore an interesting mandate for you if you wish to keep control over the sale of your property, but which can however be particularly counterproductive.

    #### The exclusive mandate

    The exclusive sales mandate entrusts the sale of the property to a single real estate agency. The communication about the property is much more coherent here. Moreover, the real estate agency, knowing it is the only one in the running to sell the property, will put all the necessary financial and human resources to maximise the sale in the best time and conditions.

    Strategies relating to the sale of the property will be decided by a single team, which will allow buyers to see a coherent offer. The feeling of reliability is decisive in the subsequent negotiation phase. Indeed, trust between the parties during negotiations is the main ingredient of a successful sale.

    As this mandate is exclusive, you will need to choose your agent with diligence. Indeed, you will lose the freedom to sell your property yourself or to put several agencies in competition. However, by working with our agency, you will benefit from a single point of contact to centralise all requests from potential buyers or other agencies and perfectly control your property and the information disclosed.

    #### The co-exclusive mandate

    The co-exclusive mandate can be the hybrid solution in the case where neither the conditions of the simple mandate nor those of the exclusive mandate will satisfy you. This mandate is based on the same principles governing the exclusive mandate we have just presented. However, it allows you to entrust the sale of your property to two real estate agencies.

    It offers exactly the same advantages, which are a greater provision of financial and human resources from the agencies and a better harmonised communication strategy than in the simple mandate.

    When it comes to choosing between these different types of mandates, particularly if you hesitate between an exclusive or co-exclusive mandate, it is preferable to contact the agency you prefer. In this way, they can guide you towards an agent with whom a concerted effort can be made so that synergy occurs. You thus multiply forces to achieve better results.

    ### How do we sell your property?

    Our teams create a sales pitch that will accompany the visual content (HD videos and 360° HD photos) across all the networks we master (website, social media, press reviews, etc.). Once a buyer is interested, we arrange a visit to the property accompanied by one of our negotiators.

    Following this process, if the client is interested in the property, we draft a purchase offer outlining their conditions, accompanied by a cheque for 10% of the proposed amount, made out to the notary, to prove their good faith in acquiring the property. Note that we are in constant communication with the seller and the buyer throughout the sales process. If there is agreement on the price and the property, we make an appointment with a Notary of the Principality for the signing of the preliminary sales agreement. The cheque is cashed as a deposit against the sale price of the property.

    As we highlighted in our buying guide for settling in Monaco, the signing of a preliminary sales agreement is not mandatory, but may be necessary, particularly in the context of the Monegasque State's right of pre-emption. This right applies to all buildings constructed before 1947.

    Finally, after all the conditions precedent have been met within the allotted time, it will then be time to meet again at the Notary's office for the signing of the authentic deed, at which date the buyer must pay in full the amount corresponding to the price of said property, minus the deposit, as well as the notary fees of 6% and the agency commission of 3% excluding tax on the property price, according to the Monegasque real estate chamber's tariff schedule. In the event that one of the conditions precedent is not met, the deposit cheque will be refunded to the buyer and the sale will be deemed cancelled.

    ### Payment of funds

    Once the documents are signed before the notary, the funds will be paid to you by the notary's office within 15 days, minus the seller's agency fees, set according to the Monegasque real estate chamber's tariff schedule at 5% excluding tax on the sale price.

    We hope you now know more about our process for selling a property in Monaco.
  BODY
  "it" => <<~BODY,
    Il nostro team di esperti vi accompagna in tutte le tappe necessarie per la realizzazione del vostro progetto di vendita a Monaco.

    ### Stimate il valore del vostro immobile

    Una buona stima del vostro immobile permetterà di concludere una vendita rapida, poiché il valore reale del vostro immobile attirerà i giusti acquirenti. Per apprezzare il valore reale del vostro immobile, uno dei nostri negoziatori verrà a visitare il vostro immobile per raccogliere il massimo di elementi che consentano di stimare il giusto prezzo.

    ### Gestiamo tutta la parte amministrativa della vendita

    Ci occupiamo di tutto affinché la vostra esperienza sia la più piacevole possibile.

    Raccogliamo presso di voi l'insieme dei documenti necessari per la vendita del vostro immobile, ossia:

    - la vostra attestazione di proprietà dell'immobile da vendere,
    - una copia dei vostri documenti d'identità (passaporto e carta d'identità e/o permesso di soggiorno in corso di validità)
    - una copia di un giustificativo di domicilio
    - gli ultimi tre verbali dell'assemblea generale di condominio,
    - il regolamento di condominio,
    - l'insieme dei documenti giuridici relativi alla vostra società, se effettuate la vendita in qualità di persona giuridica,
    - il fascicolo di gestione locativa se l'immobile che vendete è oggetto di un contratto di locazione,
    - il fascicolo di collaudo dei lavori nel quadro di cantieri soggetti a permesso.

    Una volta completato il vostro fascicolo, il nostro team vi proporrà la conclusione di un mandato di vendita. Si tratta di un contratto che indica il prezzo di vendita, la nostra remunerazione, la sua durata e le sue condizioni. È un contratto bilaterale che ci impegna reciprocamente.

    ### Tutto sapere sul mandato di vendita

    Il mandato di vendita può assumere tre forme. Può essere semplice, esclusivo o co-esclusivo:

    #### Il mandato di vendita semplice

    Questo tipo di mandato vi permette di affidare la vendita del vostro immobile a diverse agenzie immobiliari (più giuridicamente chiamate mandatari). Vi lascia anche l'opportunità di vendere il vostro immobile da soli. Il mandatario che sarà riuscito a mettervi in relazione con un acquirente e a dirigere le negoziazioni sarà l'unico a essere remunerato per il suo servizio.

    Questo tipo di mandato vi lascia una grande libertà d'azione, ma ha tuttavia aspetti negativi. La grande concorrenza tra i prestatori diminuisce altrettanto le loro possibilità di essere remunerati. Il che tende spesso a limitare il coinvolgimento dei nostri concorrenti. Inoltre, è frequente vedere lo stesso immobile annunciato con informazioni diverse come il prezzo di vendita, la superficie... il che rappresenta un serio handicap nelle negoziazioni con i potenziali acquirenti.

    È dunque un mandato interessante per voi se desiderate mantenere il controllo sulla vendita del vostro immobile, ma che può tuttavia essere particolarmente controproducente.

    #### Il mandato esclusivo

    Il mandato di vendita esclusivo affida la vendita dell'immobile a una sola agenzia immobiliare. La comunicazione sull'immobile è qui molto più coerente. Inoltre, l'agenzia immobiliare, sapendosi unica in corsa per vendere l'immobile, vi metterà tutte le risorse finanziarie e umane necessarie per massimizzare la vendita nei migliori tempi e condizioni.

    Le strategie relative alla vendita dell'immobile saranno decise da un unico team, il che permetterà agli acquirenti di vedere un'offerta coerente. Il sentimento di affidabilità è determinante nella fase successiva delle negoziazioni. In effetti, la fiducia tra le parti durante le negoziazioni è l'ingrediente principale di una vendita riuscita.

    Essendo questo mandato esclusivo, dovrete scegliere il vostro mandatario con diligenza. In effetti, perderete la libertà di vendere il vostro immobile da soli o di mettere in concorrenza diverse agenzie. Tuttavia, lavorando con la nostra agenzia, beneficerete di un unico interlocutore per centralizzare tutte le richieste di potenziali acquirenti o di altre agenzie e controllare perfettamente il vostro immobile e le informazioni divulgate.

    #### Il mandato co-esclusivo

    Il mandato co-esclusivo può essere la soluzione ibrida nel caso in cui né le condizioni del mandato semplice, né quelle del mandato esclusivo, vi soddisfino. Questo mandato si basa sugli stessi principi che regolano il mandato esclusivo che abbiamo appena presentato. Tuttavia, vi permette di affidare la vendita del vostro immobile a due agenzie immobiliari.

    Presenta esattamente gli stessi vantaggi, che sono una maggiore messa a disposizione di risorse finanziarie e umane da parte delle agenzie e una strategia di comunicazione meglio armonizzata rispetto al mandato semplice.

    Quando si tratta di scegliere tra questi diversi tipi di mandati, in particolare se esitate tra un mandato esclusivo o co-esclusivo, è preferibile prendere contatto con l'agenzia che privilegiate. In questo modo, potrà orientarvi verso un mandatario con il quale un lavoro di concerto potrà essere realizzato affinché si crei una sinergia. Moltiplicate così le forze per arrivare a migliori risultati.

    ### Come vendiamo il vostro immobile?

    I nostri team realizzano un argomentario di vendita che accompagnerà i contenuti visivi (video HD e foto HD a 360°) su tutti i canali che padroneggiamo (sito internet, social media, rassegne stampa ecc.). Una volta che un acquirente è interessato, organizziamo la visita dell'immobile in compagnia di uno dei nostri negoziatori.

    A seguito di questo processo, se il cliente è interessato all'immobile, redigiamo un'offerta d'acquisto riportante le sue condizioni, accompagnata da un assegno di un importo del 10% della somma proposta, all'ordine del notaio, per provare la sua buona volontà di acquisire l'immobile. Da notare che siamo in comunicazione costante con il venditore e l'acquirente durante tutta la durata del processo di vendita. Nel caso in cui ci sia accordo sul prezzo e sulla cosa, prendiamo appuntamento presso un Notaio del Principato per la firma del compromesso di vendita. L'assegno viene incassato a titolo di acconto sul prezzo di vendita dell'immobile.

    Come abbiamo sottolineato nella nostra guida all'acquisto per installarsi a Monaco, la firma di un compromesso di vendita non è obbligatoria, ma può essere necessaria, in particolare nel quadro del diritto di prelazione dello Stato monegasco. Questo diritto si applica a tutti gli immobili costruiti prima del 1947.

    Infine, dopo che tutte le condizioni sospensive siano state soddisfatte nei termini previsti, sarà allora il momento di ritrovarsi nuovamente dal Notaio per la firma dell'atto autentico, data alla quale l'acquirente dovrà regolare integralmente l'importo corrispondente al prezzo del suddetto immobile, dedotto l'acconto, nonché le spese notarili del 6% e la commissione d'agenzia del 3% al netto delle tasse sul prezzo dell'immobile, secondo il tariffario della camera immobiliare monegasca. Nel caso in cui una delle condizioni sospensive non sia soddisfatta, l'assegno di acconto sarà rimborsato all'acquirente e la vendita sarà dichiarata annullata.

    ### Il versamento dei fondi

    Una volta firmati i documenti davanti al notaio, i fondi vi saranno versati dallo studio notarile entro 15 giorni, dedotti gli onorari d'agenzia del venditore, fissati secondo il tariffario della camera immobiliare monegasca al 5% al netto delle tasse sul prezzo di vendita.

    Speriamo che ora sappiate di più sul nostro processo di vendita di un immobile a Monaco.
  BODY
  "de" => <<~BODY,
    Unser Expertenteam begleitet Sie durch alle notwendigen Schritte zur Verwirklichung Ihres Verkaufsprojekts in Monaco.

    ### Schätzen Sie den Wert Ihrer Immobilie

    Eine gute Schätzung Ihrer Immobilie ermöglicht einen schnellen Verkauf, da der reale Wert Ihrer Immobilie die richtigen Käufer anzieht. Um den realen Wert Ihrer Immobilie zu beurteilen, wird einer unserer Verhandler Ihre Immobilie besichtigen, um so viele Elemente wie möglich zu sammeln, die eine Schätzung des richtigen Preises ermöglichen.

    ### Wir übernehmen den gesamten administrativen Teil des Verkaufs

    Wir kümmern uns um alles, damit Ihre Erfahrung so angenehm wie möglich ist.

    Wir sammeln bei Ihnen alle für den Verkauf Ihrer Immobilie erforderlichen Dokumente, nämlich:

    - Ihre Eigentumsbestätigung der zu verkaufenden Immobilie,
    - eine Kopie Ihrer Ausweisdokumente (Reisepass und Personalausweis und/oder gültiger Aufenthaltstitel)
    - eine Kopie eines Wohnsitznachweises
    - die letzten drei Protokolle der Eigentümerversammlung,
    - die Teilungserklärung,
    - alle rechtlichen Dokumente zu Ihrer Gesellschaft, wenn Sie den Verkauf als juristische Person durchführen,
    - die Mietverwaltungsakte, wenn die zu verkaufende Immobilie einem Mietvertrag unterliegt,
    - die Bestandsakte der Arbeiten im Rahmen genehmigungspflichtiger Bauprojekte.

    Sobald Ihre Akte vollständig ist, wird unser Team Ihnen den Abschluss eines Verkaufsauftrags vorschlagen. Es handelt sich um einen Vertrag, der den Verkaufspreis, unsere Vergütung, seine Dauer und seine Bedingungen angibt. Es handelt sich um einen bilateralen Vertrag, der uns gegenseitig bindet.

    ### Alles Wissenswerte über den Verkaufsauftrag

    Der Verkaufsauftrag kann drei Formen annehmen. Er kann einfach, exklusiv oder ko-exklusiv sein:

    #### Der einfache Verkaufsauftrag

    Dieser Auftragstyp ermöglicht es Ihnen, den Verkauf Ihrer Immobilie mehreren Immobilienagenturen anzuvertrauen (juristisch als Beauftragte bezeichnet). Er lässt Ihnen auch die Möglichkeit, Ihre Immobilie selbst zu verkaufen. Der Beauftragte, dem es gelungen ist, Sie mit einem Käufer zusammenzubringen und die Verhandlungen zu führen, ist der einzige, der für seinen Dienst vergütet wird.

    Dieser Auftragstyp gibt Ihnen große Handlungsfreiheit, hat aber negative Aspekte. Der große Wettbewerb zwischen den Anbietern verringert ihre Chancen, vergütet zu werden. Dies neigt oft dazu, das Engagement unserer Konkurrenten zu begrenzen. Außerdem ist es häufig, dass dieselbe Immobilie mit unterschiedlichen Informationen wie Verkaufspreis, Fläche... beworben wird, was ein ernstes Handicap in Verhandlungen mit potenziellen Käufern darstellt.

    Es ist also ein interessanter Auftrag für Sie, wenn Sie die Kontrolle über den Verkauf Ihrer Immobilie behalten möchten, der aber besonders kontraproduktiv sein kann.

    #### Der Exklusivauftrag

    Der exklusive Verkaufsauftrag vertraut den Verkauf der Immobilie einer einzigen Immobilienagentur an. Die Kommunikation über die Immobilie ist hier viel kohärenter. Zudem wird die Immobilienagentur, die weiß, dass sie allein im Rennen um den Verkauf der Immobilie ist, alle notwendigen finanziellen und personellen Ressourcen einsetzen, um den Verkauf in kürzester Zeit und unter besten Bedingungen zu maximieren.

    Die Strategien bezüglich des Verkaufs der Immobilie werden von einem einzigen Team entschieden, was den Käufern ein kohärentes Angebot zeigen wird. Das Gefühl der Zuverlässigkeit ist in der nachfolgenden Verhandlungsphase entscheidend. In der Tat ist Vertrauen zwischen den Parteien bei Verhandlungen die Hauptzutat für einen erfolgreichen Verkauf.

    Da dieser Auftrag exklusiv ist, müssen Sie Ihren Beauftragten mit Sorgfalt auswählen. In der Tat verlieren Sie die Freiheit, Ihre Immobilie selbst zu verkaufen oder mehrere Agenturen in Konkurrenz zu setzen. Durch die Zusammenarbeit mit unserer Agentur profitieren Sie jedoch von einem einzigen Ansprechpartner, um alle Anfragen potenzieller Käufer oder anderer Agenturen zu zentralisieren und Ihre Immobilie und die veröffentlichten Informationen perfekt zu kontrollieren.

    #### Der ko-exklusive Auftrag

    Der ko-exklusive Auftrag kann die hybride Lösung sein, falls weder die Bedingungen des einfachen noch die des exklusiven Auftrags Sie zufriedenstellen. Dieser Auftrag beruht auf den gleichen Prinzipien wie der soeben vorgestellte Exklusivauftrag. Er ermöglicht es Ihnen jedoch, den Verkauf Ihrer Immobilie zwei Immobilienagenturen anzuvertrauen.

    Er bietet genau die gleichen Vorteile, nämlich eine größere Bereitstellung von finanziellen und personellen Ressourcen seitens der Agenturen und eine besser abgestimmte Kommunikationsstrategie als beim einfachen Auftrag.

    Wenn es darum geht, zwischen diesen verschiedenen Auftragstypen zu wählen, insbesondere wenn Sie zwischen einem exklusiven oder ko-exklusiven Auftrag zögern, ist es vorzuziehen, die Agentur Ihrer Wahl zu kontaktieren. Auf diese Weise kann sie Sie zu einem Beauftragten orientieren, mit dem eine gemeinsame Arbeit durchgeführt werden kann, damit Synergien entstehen. Sie vervielfachen so die Kräfte, um bessere Ergebnisse zu erzielen.

    ### Wie verkaufen wir Ihre Immobilie?

    Unsere Teams erstellen ein Verkaufsargumentarium, das die visuellen Inhalte (HD-Videos und 360°-HD-Fotos) auf allen Kanälen begleitet, die wir beherrschen (Website, soziale Medien, Presseschauen usw.). Sobald ein Käufer interessiert ist, organisieren wir eine Besichtigung der Immobilie in Begleitung eines unserer Verhandler.

    Im Anschluss an diesen Prozess erstellen wir, wenn der Kunde an der Immobilie interessiert ist, ein Kaufangebot mit seinen Bedingungen, begleitet von einem Scheck über 10% der vorgeschlagenen Summe, ausgestellt auf den Notar, um seinen guten Willen zum Erwerb der Immobilie zu beweisen. Es ist zu beachten, dass wir während des gesamten Verkaufsprozesses in ständiger Kommunikation mit dem Verkäufer und dem Käufer stehen. Im Falle einer Einigung über den Preis und die Sache vereinbaren wir einen Termin bei einem Notar des Fürstentums zur Unterzeichnung des Vorvertrags. Der Scheck wird als Anzahlung auf den Verkaufspreis der Immobilie eingelöst.

    Wie wir in unserem Kaufleitfaden für die Niederlassung in Monaco hervorgehoben haben, ist die Unterzeichnung eines Vorvertrags nicht obligatorisch, kann aber notwendig sein, insbesondere im Rahmen des Vorkaufsrechts des monegassischen Staates. Dieses Recht gilt für alle vor 1947 errichteten Gebäude.

    Schließlich, nachdem alle aufschiebenden Bedingungen innerhalb der vorgesehenen Fristen erfüllt sind, ist es dann Zeit, sich erneut beim Notar zur Unterzeichnung der notariellen Urkunde zu treffen, zu welchem Datum der Erwerber den vollständigen Betrag des Preises der besagten Immobilie abzüglich der Anzahlung sowie die Notargebühren von 6% und die Agenturprovision von 3% zzgl. Steuer auf den Immobilienpreis gemäß dem Tarif der monegassischen Immobilienkammer zu begleichen hat. Falls eine der aufschiebenden Bedingungen nicht erfüllt wird, wird der Anzahlungsscheck dem Käufer erstattet und der Verkauf gilt als storniert.

    ### Die Auszahlung der Mittel

    Sobald die Dokumente vor dem Notar unterzeichnet sind, werden Ihnen die Mittel innerhalb von 15 Tagen vom Notariat ausgezahlt, abzüglich der Verkäufer-Agenturgebühren, die gemäß dem Tarif der monegassischen Immobilienkammer auf 5% zzgl. Steuer auf den Verkaufspreis festgelegt sind.

    Wir hoffen, dass Sie nun mehr über unseren Prozess des Immobilienverkaufs in Monaco wissen.
  BODY
  "sv" => <<~BODY,
    Vårt expertteam stöder dig genom alla nödvändiga steg för genomförandet av ditt försäljningsprojekt i Monaco.

    ### Uppskatta värdet på din fastighet

    En bra uppskattning av din fastighet möjliggör en snabb försäljning, eftersom det verkliga värdet på din fastighet kommer att attrahera rätt köpare. För att bedöma det verkliga värdet på din fastighet kommer en av våra förhandlare att besöka din fastighet för att samla så många element som möjligt för att uppskatta rätt pris.

    ### Vi hanterar hela den administrativa delen av försäljningen

    Vi tar hand om allt så att din upplevelse blir så behaglig som möjligt.

    Vi samlar in alla nödvändiga dokument för försäljningen av din fastighet, nämligen:

    - ditt ägarintyg för fastigheten som ska säljas,
    - en kopia av dina identitetshandlingar (pass och identitetskort och/eller giltigt uppehållstillstånd)
    - en kopia av adressbevis
    - de tre senaste protokollen från bostadsrättsföreningens årsstämma,
    - bostadsrättsföreningens stadgar,
    - alla juridiska dokument som rör ditt företag, om du säljer som juridisk person,
    - hyresförvaltningsakten om fastigheten du säljer är föremål för ett hyresavtal,
    - slutbesiktningsakten för arbeten som kräver bygglov.

    När din akt är komplett kommer vårt team att föreslå ett försäljningsuppdrag. Det är ett kontrakt som anger försäljningspriset, vår ersättning, dess varaktighet och villkor. Det är ett bilateralt kontrakt som binder oss ömsesidigt.

    ### Allt du behöver veta om försäljningsuppdraget

    Försäljningsuppdraget kan ta tre former. Det kan vara enkelt, exklusivt eller samexklusivt:

    #### Det enkla försäljningsuppdraget

    Denna typ av uppdrag gör det möjligt för dig att anförtro försäljningen av din fastighet till flera fastighetsbyråer. Det ger dig också möjligheten att sälja din fastighet själv. Den agent som har lyckats koppla dig samman med en köpare och leda förhandlingarna kommer att vara den enda som ersätts för sin tjänst.

    Denna typ av uppdrag ger dig stor handlingsfrihet, men har negativa aspekter. Den stora konkurrensen mellan leverantörerna minskar deras chanser att bli ersatta. Detta tenderar ofta att begränsa engagemanget hos våra konkurrenter. Dessutom är det vanligt att se samma fastighet annonserad med olika information såsom försäljningspris, yta... vilket är ett allvarligt handikapp i förhandlingar med potentiella köpare.

    Det är alltså ett intressant uppdrag för dig om du vill behålla kontrollen över försäljningen av din fastighet, men som dock kan vara särskilt kontraproduktivt.

    #### Det exklusiva uppdraget

    Det exklusiva försäljningsuppdraget anförtror försäljningen av fastigheten till en enda fastighetsbyrå. Kommunikationen om fastigheten är här mycket mer sammanhängande. Dessutom kommer fastighetsbyrån, som vet att den är ensam om att sälja fastigheten, att lägga alla nödvändiga ekonomiska och mänskliga resurser för att maximera försäljningen på bästa tid och villkor.

    Strategier relaterade till försäljningen av fastigheten kommer att beslutas av ett enda team, vilket gör att köpare ser ett sammanhängande erbjudande. Känslan av tillförlitlighet är avgörande i den efterföljande förhandlingsfasen. Förtroende mellan parterna vid förhandlingar är huvudingrediensen i en framgångsrik försäljning.

    Eftersom detta uppdrag är exklusivt måste du välja din agent med omsorg. Du förlorar friheten att sälja din fastighet själv eller att sätta flera byråer i konkurrens. Genom att arbeta med vår byrå drar du dock nytta av en enda kontaktpunkt för att centralisera alla förfrågningar från potentiella köpare eller andra byråer och perfekt kontrollera din fastighet och den information som lämnas ut.

    #### Det samexklusiva uppdraget

    Det samexklusiva uppdraget kan vara den hybrida lösningen om varken villkoren för det enkla eller det exklusiva uppdraget tillfredsställer dig. Detta uppdrag bygger på samma principer som det exklusiva uppdraget vi just har presenterat. Det gör det dock möjligt för dig att anförtro försäljningen av din fastighet till två fastighetsbyråer.

    Det erbjuder exakt samma fördelar, nämligen en större tillgång på ekonomiska och mänskliga resurser från byråerna och en bättre harmoniserad kommunikationsstrategi än i det enkla uppdraget.

    När det gäller att välja mellan dessa olika typer av uppdrag, särskilt om du tvekar mellan ett exklusivt eller samexklusivt uppdrag, är det att föredra att kontakta den byrå du föredrar. På detta sätt kan den vägleda dig till en agent med vilken ett samordnat arbete kan genomföras så att synergi uppstår. Du multiplicerar således krafterna för att uppnå bättre resultat.

    ### Hur säljer vi din fastighet?

    Våra team skapar ett försäljningsargument som åtföljer det visuella innehållet (HD-videor och 360° HD-foton) på alla kanaler vi behärskar (webbplats, sociala medier, pressrecensioner etc.). När en köpare är intresserad arrangerar vi en visning av fastigheten i sällskap med en av våra förhandlare.

    Efter denna process, om kunden är intresserad av fastigheten, upprättar vi ett köperbjudande med dennes villkor, åtföljt av en check på 10% av det föreslagna beloppet, utställd till notarien, för att bevisa god vilja att förvärva fastigheten. Observera att vi är i konstant kommunikation med säljaren och köparen under hela försäljningsprocessen. Om det finns enighet om priset och egendomen bokar vi tid hos en notarie i Furstendömet för undertecknande av det preliminära köpeavtalet. Checken löses in som handpenning mot försäljningspriset.

    Som vi betonade i vår köpguide för att bosätta sig i Monaco är undertecknandet av ett preliminärt köpeavtal inte obligatoriskt, men kan vara nödvändigt, särskilt inom ramen för den monegaskiska statens förköpsrätt. Denna rätt gäller för alla byggnader uppförda före 1947.

    Slutligen, efter att alla villkor har uppfyllts inom den angivna tiden, är det dags att åter träffas hos notarien för undertecknande av det autentiska dokumentet, vid vilket datum köparen måste betala hela beloppet motsvarande priset för nämnda fastighet, minus handpenningen, samt notarieavgifterna på 6% och byråprovisionen på 3% exklusive moms på fastighetspriset, enligt den monegaskiska fastighetskammarens tariff. Om ett av villkoren inte uppfylls återbetalas handpenningen till köparen och försäljningen anses annullerad.

    ### Utbetalning av medel

    När dokumenten är undertecknade hos notarien betalas medlen ut till dig av notariekontoret inom 15 dagar, minus säljarens byråavgifter, fastställda enligt den monegaskiska fastighetskammarens tariff till 5% exklusive moms på försäljningspriset.

    Vi hoppas att du nu vet mer om vår process för att sälja en fastighet i Monaco.
  BODY
  "no" => <<~BODY,
    Vårt ekspertteam støtter deg gjennom alle nødvendige trinn for gjennomføringen av ditt salgsprosjekt i Monaco.

    ### Estimer verdien av eiendommen din

    Et godt estimat av eiendommen din vil bidra til et raskt salg, ettersom den reelle verdien av eiendommen din vil tiltrekke de rette kjøperne. For å vurdere den reelle verdien av eiendommen din, vil en av våre forhandlere besøke eiendommen din for å samle så mange elementer som mulig for å estimere riktig pris.

    ### Vi håndterer hele den administrative delen av salget

    Vi tar hånd om alt slik at din opplevelse blir så behagelig som mulig.

    Vi samler inn alle dokumentene som er nødvendige for salget av eiendommen din, nemlig:

    - din eierskapsattest for eiendommen som skal selges,
    - en kopi av dine identitetsdokumenter (pass og identitetskort og/eller gyldig oppholdstillatelse)
    - en kopi av adressebevis
    - de tre siste protokollene fra sameiets generalforsamling,
    - sameiets vedtekter,
    - alle juridiske dokumenter relatert til ditt selskap, dersom du selger som juridisk person,
    - utleiehåndteringsfilen dersom eiendommen du selger er gjenstand for en leiekontrakt,
    - sluttdokumentasjon for arbeider underlagt byggetillatelse.

    Når filen din er komplett, vil teamet vårt foreslå inngåelse av et salgsoppdrag. Det er en kontrakt som angir salgsprisen, vår godtgjørelse, varigheten og betingelsene. Det er en bilateral kontrakt som forplikter oss gjensidig.

    ### Alt du trenger å vite om salgsoppdraget

    Salgsoppdraget kan ta tre former. Det kan være enkelt, eksklusivt eller sam-eksklusivt:

    #### Det enkle salgsoppdraget

    Denne typen oppdrag lar deg overlate salget av eiendommen din til flere eiendomsmeglere. Det gir deg også muligheten til å selge eiendommen selv. Megleren som har lyktes med å koble deg med en kjøper og lede forhandlingene, vil være den eneste som honoreres for sin tjeneste.

    Denne typen oppdrag gir deg stor handlefrihet, men har negative aspekter. Den store konkurransen mellom tilbyderne reduserer deres sjanser for å bli honorert. Dette har ofte en tendens til å begrense engasjementet til våre konkurrenter. Dessuten er det vanlig å se den samme eiendommen annonsert med forskjellig informasjon som salgspris, areal... noe som er et alvorlig handikap i forhandlinger med potensielle kjøpere.

    Det er altså et interessant oppdrag for deg dersom du ønsker å beholde kontrollen over salget av eiendommen din, men som likevel kan være særlig kontraproduktivt.

    #### Det eksklusive oppdraget

    Det eksklusive salgsoppdraget overlater salget av eiendommen til et enkelt eiendomsmeglerforetak. Kommunikasjonen om eiendommen er her mye mer sammenhengende. I tillegg vil eiendomsmeglerforetaket, som vet at det er alene om å selge eiendommen, bruke alle nødvendige økonomiske og menneskelige ressurser for å maksimere salget på best mulig tid og vilkår.

    Strategier knyttet til salget av eiendommen vil bli bestemt av et enkelt team, noe som gjør at kjøpere ser et sammenhengende tilbud. Følelsen av pålitelighet er avgjørende i den påfølgende forhandlingsfasen. Tillit mellom partene under forhandlinger er hovedingrediensen for et vellykket salg.

    Ettersom dette oppdraget er eksklusivt, må du velge din megler med omhu. Du mister friheten til å selge eiendommen din selv eller sette flere byråer i konkurranse. Ved å jobbe med vårt byrå drar du imidlertid nytte av ett enkelt kontaktpunkt for å sentralisere alle henvendelser fra potensielle kjøpere eller andre byråer og perfekt kontrollere eiendommen din og informasjonen som gis ut.

    #### Det sam-eksklusive oppdraget

    Det sam-eksklusive oppdraget kan være den hybride løsningen dersom verken betingelsene for det enkle eller det eksklusive oppdraget tilfredsstiller deg. Dette oppdraget bygger på de samme prinsippene som det eksklusive oppdraget vi nettopp har presentert. Det lar deg imidlertid overlate salget av eiendommen din til to eiendomsmeglerforetak.

    Det tilbyr nøyaktig de samme fordelene, som er større tilgang på økonomiske og menneskelige ressurser fra byråene og en bedre harmonisert kommunikasjonsstrategi enn i det enkle oppdraget.

    Når det gjelder å velge mellom disse ulike typene oppdrag, spesielt om du nøler mellom et eksklusivt eller sam-eksklusivt oppdrag, er det å foretrekke å kontakte byrået du foretrekker. På denne måten kan det veilede deg til en megler som det kan gjennomføres et samordnet arbeid med slik at synergi oppstår. Du multipliserer dermed kreftene for å oppnå bedre resultater.

    ### Hvordan selger vi eiendommen din?

    Teamene våre lager et salgsargument som følger det visuelle innholdet (HD-videoer og 360° HD-bilder) på alle kanalene vi behersker (nettsted, sosiale medier, presseanmeldelser osv.). Når en kjøper er interessert, arrangerer vi en visning av eiendommen i følge med en av våre forhandlere.

    Etter denne prosessen, dersom kunden er interessert i eiendommen, utarbeider vi et kjøpstilbud med hans betingelser, ledsaget av en sjekk på 10% av det foreslåtte beløpet, utstedt til notaren, for å bevise god vilje til å erverve eiendommen. Merk at vi er i konstant kommunikasjon med selger og kjøper gjennom hele salgsprosessen. Dersom det er enighet om pris og eiendommen, avtaler vi time hos en notar i Fyrstedømmet for undertegning av den foreløpige kjøpsavtalen. Sjekken innløses som forskudd på salgsprisen.

    Som vi fremhevet i vår kjøpsguide for å bosette seg i Monaco, er undertegning av en foreløpig kjøpsavtale ikke obligatorisk, men kan være nødvendig, spesielt i forbindelse med den monegaskiske statens forkjøpsrett. Denne retten gjelder for alle bygninger oppført før 1947.

    Til slutt, etter at alle betingelsene er oppfylt innen de fastsatte fristene, er det tid for å møtes igjen hos notaren for undertegning av det autentiske dokumentet, på hvilken dato kjøperen må betale hele beløpet tilsvarende prisen for nevnte eiendom, fratrukket forskuddet, samt notaravgiftene på 6% og meglerprovisjonene på 3% eks. mva. på eiendomsprisen, i henhold til den monegaskiske eiendomskammerets tariff. Dersom en av betingelsene ikke er oppfylt, vil forskuddsjekken bli refundert til kjøperen og salget anses som annullert.

    ### Utbetaling av midler

    Når dokumentene er undertegnet hos notaren, vil midlene bli utbetalt til deg fra notarkontoret innen 15 dager, fratrukket selgers meglerhonorar, fastsatt i henhold til den monegaskiske eiendomskammerets tariff til 5% eks. mva. på salgsprisen.

    Vi håper at du nå vet mer om vår prosess for salg av eiendom i Monaco.
  BODY
  "da" => <<~BODY,
    Vores ekspertteam støtter dig gennem alle de nødvendige trin for gennemførelsen af dit salgsprojekt i Monaco.

    ### Vurder værdien af din ejendom

    En god vurdering af din ejendom vil bidrage til et hurtigt salg, da den reelle værdi af din ejendom vil tiltrække de rette købere. For at vurdere den reelle værdi af din ejendom vil en af vores forhandlere besøge din ejendom for at indsamle så mange elementer som muligt til at estimere den rette pris.

    ### Vi håndterer hele den administrative del af salget

    Vi tager os af alt, så din oplevelse bliver så behagelig som muligt.

    Vi indsamler alle de nødvendige dokumenter til salget af din ejendom, nemlig:

    - din ejendomsattest for ejendommen, der skal sælges,
    - en kopi af dine identitetsdokumenter (pas og identitetskort og/eller gyldig opholdstilladelse)
    - en kopi af adressebevis
    - de tre seneste referater fra ejerforeningens generalforsamling,
    - ejerforeningens vedtægter,
    - alle juridiske dokumenter vedrørende dit selskab, hvis du sælger som juridisk person,
    - udlejningsforvaltningsfilen, hvis ejendommen du sælger er genstand for en lejekontrakt,
    - slutdokumentationen for arbejder, der kræver byggetilladelse.

    Når din fil er komplet, vil vores team foreslå indgåelsen af et salgsmandat. Det er en kontrakt, der angiver salgsprisen, vores honorar, dets varighed og betingelser. Det er en bilateral kontrakt, der forpligter os gensidigt.

    ### Alt du behøver at vide om salgsmandatet

    Salgsmandatet kan antage tre former. Det kan være enkelt, eksklusivt eller sam-eksklusivt:

    #### Det enkle salgsmandat

    Denne type mandat giver dig mulighed for at overlade salget af din ejendom til flere ejendomsmæglere. Det giver dig også muligheden for at sælge din ejendom selv. Den mægler, der har formået at sætte dig i forbindelse med en køber og lede forhandlingerne, vil være den eneste, der honoreres for sin tjeneste.

    Denne type mandat giver dig stor handlefrihed, men har negative aspekter. Den store konkurrence mellem udbyderne reducerer deres chancer for at blive honoreret. Dette har ofte tendens til at begrænse engagementet hos vores konkurrenter. Desuden er det almindeligt at se den samme ejendom annonceret med forskellige oplysninger som salgspris, areal... hvilket er et alvorligt handicap i forhandlinger med potentielle købere.

    Det er altså et interessant mandat for dig, hvis du ønsker at bevare kontrollen over salget af din ejendom, men som dog kan være særligt kontraproduktivt.

    #### Det eksklusive mandat

    Det eksklusive salgsmandat overlader salget af ejendommen til et enkelt ejendomsmæglerfirma. Kommunikationen om ejendommen er her meget mere sammenhængende. Desuden vil ejendomsmæglerfirmaet, der ved, at det er alene om at sælge ejendommen, bruge alle nødvendige økonomiske og menneskelige ressourcer for at maksimere salget på bedst mulig tid og vilkår.

    Strategier vedrørende salget af ejendommen vil blive besluttet af et enkelt team, hvilket gør det muligt for købere at se et sammenhængende tilbud. Følelsen af pålidelighed er afgørende i den efterfølgende forhandlingsfase. Tillid mellem parterne under forhandlinger er hovedingrediensen i et vellykket salg.

    Da dette mandat er eksklusivt, skal du vælge din mægler med omhu. Du mister friheden til at sælge din ejendom selv eller sætte flere bureauer i konkurrence. Ved at arbejde med vores bureau nyder du dog godt af et enkelt kontaktpunkt til at centralisere alle henvendelser fra potentielle købere eller andre bureauer og perfekt kontrollere din ejendom og de oplysninger, der gives ud.

    #### Det sam-eksklusive mandat

    Det sam-eksklusive mandat kan være den hybride løsning, hvis hverken betingelserne for det enkle eller det eksklusive mandat tilfredsstiller dig. Dette mandat bygger på de samme principper som det eksklusive mandat, vi netop har præsenteret. Det giver dig dog mulighed for at overlade salget af din ejendom til to ejendomsmæglerfirmaer.

    Det tilbyder nøjagtigt de samme fordele, nemlig en større rådighed over økonomiske og menneskelige ressourcer fra bureauerne og en bedre harmoniseret kommunikationsstrategi end i det enkle mandat.

    Når det drejer sig om at vælge mellem disse forskellige typer mandater, især hvis du tøver mellem et eksklusivt eller sam-eksklusivt mandat, er det at foretrække at kontakte det bureau, du foretrækker. På denne måde kan det guide dig til en mægler, med hvem et koordineret arbejde kan udføres, så der opstår synergi. Du multiplicerer dermed kræfterne for at opnå bedre resultater.

    ### Hvordan sælger vi din ejendom?

    Vores teams skaber et salgsargument, der ledsager det visuelle indhold (HD-videoer og 360° HD-fotos) på alle de kanaler, vi behersker (hjemmeside, sociale medier, presseanmeldelser osv.). Når en køber er interesseret, arrangerer vi en fremvisning af ejendommen ledsaget af en af vores forhandlere.

    Efter denne proces, hvis kunden er interesseret i ejendommen, udarbejder vi et købstilbud med hans betingelser, ledsaget af en check på 10% af det foreslåede beløb, udstedt til notaren, for at bevise god vilje til at erhverve ejendommen. Bemærk, at vi er i konstant kommunikation med sælger og køber under hele salgsprocessen. Hvis der er enighed om prisen og ejendommen, aftaler vi tid hos en notar i Fyrstendømmet til underskrift af den foreløbige købsaftale. Checken indløses som forskud på salgsprisen.

    Som vi fremhævede i vores købsguide for at bosætte sig i Monaco, er underskrift af en foreløbig købsaftale ikke obligatorisk, men kan være nødvendig, især i forbindelse med den monegaskiske stats forkøbsret. Denne ret gælder for alle bygninger opført før 1947.

    Endelig, efter at alle betingelserne er opfyldt inden for de fastsatte frister, er det tid til at mødes igen hos notaren for underskrift af det autentiske dokument, på hvilken dato køberen skal betale det fulde beløb svarende til prisen for nævnte ejendom, fratrukket forskuddet, samt notargebyrerne på 6% og mæglerprovision på 3% ekskl. moms af ejendomsprisen, i henhold til den monegaskiske ejendomskammers tarif. I tilfælde af at en af betingelserne ikke er opfyldt, vil forskudschecken blive refunderet til køberen, og salget anses for annulleret.

    ### Udbetaling af midler

    Når dokumenterne er underskrevet hos notaren, vil midlerne blive udbetalt til dig af notarkontoret inden for 15 dage, fratrukket sælgers mæglerhonorarer, fastsat i henhold til den monegaskiske ejendomskammers tarif til 5% ekskl. moms af salgsprisen.

    Vi håber, at du nu ved mere om vores proces for salg af ejendom i Monaco.
  BODY
  "fi" => <<~BODY,
    Asiantuntijatiimimme tukee sinua kaikissa tarvittavissa vaiheissa kiinteistösi myyntiprojektin toteuttamiseksi Monacossa.

    ### Arvioi kiinteistösi arvo

    Hyvä arvio kiinteistöstäsi mahdollistaa nopean myynnin, sillä kiinteistösi todellinen arvo houkuttelee oikeat ostajat. Kiinteistösi todellisen arvon arvioimiseksi yksi neuvottelijoistamme tulee vierailemaan kiinteistössänne kerätäkseen mahdollisimman paljon elementtejä oikean hinnan arvioimiseksi.

    ### Hoidamme kaiken hallinnollisen puolen myynnistä

    Hoidamme kaiken puolestasi, jotta kokemuksesi olisi mahdollisimman miellyttävä.

    Keräämme sinulta kaikki kiinteistösi myyntiin tarvittavat asiakirjat, eli:

    - omistustodistuksesi myytävästä kiinteistöstä,
    - kopio henkilöllisyystodistuksistasi (passi ja henkilökortti ja/tai voimassa oleva oleskelulupa)
    - kopio osoitetodistuksesta
    - kolme viimeisintä taloyhtiön yhtiökokouksen pöytäkirjaa,
    - taloyhtiön järjestyssäännöt,
    - kaikki yrityksesi oikeudelliset asiakirjat, jos myyt oikeushenkilönä,
    - vuokranhallinta-asiakirjat, jos myytävä kiinteistö on vuokrasopimuksen kohteena,
    - rakennusluvan alaisten töiden loppukatselmuspöytäkirjat.

    Kun asiakirjasi ovat valmiit, tiimimme ehdottaa myyntitoimeksiannon solmimista. Se on sopimus, joka ilmoittaa myyntihinnan, palkkiomme, keston ja ehdot. Se on kahdenvälinen sopimus, joka sitoo meitä molemmin puolin.

    ### Kaikki mitä sinun tulee tietää myyntitoimeksiannosta

    Myyntitoimeksianto voi olla kolmessa muodossa. Se voi olla yksinkertainen, yksinoikeudellinen tai jaettu yksinoikeudellinen:

    #### Yksinkertainen myyntitoimeksianto

    Tämä toimeksiantotyyppi mahdollistaa kiinteistösi myynnin uskomisen useille kiinteistönvälitystoimistoille. Se jättää sinulle myös mahdollisuuden myydä kiinteistösi itse. Välittäjä, joka on onnistunut yhdistämään sinut ostajaan ja johtamaan neuvotteluja, on ainoa, joka saa palkkion palvelustaan.

    Tämä toimeksiantotyyppi antaa sinulle suuren toimintavapauden, mutta sillä on negatiivisia puolia. Suuri kilpailu palveluntarjoajien välillä vähentää heidän mahdollisuuksiaan saada palkkio. Tämä pyrkii usein rajoittamaan kilpailijoidemme sitoutumista. Lisäksi on yleistä nähdä sama kiinteistö ilmoitettuna erilaisilla tiedoilla, kuten myyntihinta, pinta-ala... mikä on vakava haitta neuvotteluissa potentiaalisten ostajien kanssa.

    Se on siis mielenkiintoinen toimeksianto sinulle, jos haluat säilyttää hallinnan kiinteistösi myynnissä, mutta joka voi kuitenkin olla erityisen haitallinen.

    #### Yksinoikeudellinen toimeksianto

    Yksinoikeudellinen myyntitoimeksianto uskoo kiinteistön myynnin yhdelle ainoalle kiinteistönvälitystoimistolle. Kiinteistöä koskeva viestintä on tässä paljon johdonmukaisempaa. Lisäksi kiinteistönvälitystoimisto, tietäen olevansa ainoa kiinteistön myynnissä, käyttää kaikki tarvittavat taloudelliset ja inhimilliset resurssit myynnin maksimoimiseksi parhaassa ajassa ja olosuhteissa.

    Kiinteistön myyntiä koskevat strategiat päätetään yhden ainoan tiimin toimesta, mikä mahdollistaa ostajille johdonmukaisen tarjouksen näkemisen. Luotettavuuden tunne on ratkaiseva seuraavassa neuvotteluvaiheessa. Luottamus osapuolten välillä neuvotteluissa on onnistuneen myynnin pääainesosa.

    Koska tämä toimeksianto on yksinoikeudellinen, sinun on valittava välittäjäsi huolella. Menetät vapauden myydä kiinteistösi itse tai asettaa useita toimistoja kilpailuun. Toimistomme kanssa työskennellessäsi hyödyt kuitenkin yhdestä yhteyshenkilöstä kaikkien potentiaalisten ostajien tai muiden toimistojen kyselyjen keskittämiseksi ja kiinteistösi sekä luovutettujen tietojen täydelliseksi hallitsemiseksi.

    #### Jaettu yksinoikeudellinen toimeksianto

    Jaettu yksinoikeudellinen toimeksianto voi olla hybridiratkaisu, jos yksinkertaisen tai yksinoikeudellisen toimeksiannon ehdot eivät tyydytä sinua. Tämä toimeksianto perustuu samoihin periaatteisiin kuin juuri esittelemämme yksinoikeudellinen toimeksianto. Se mahdollistaa kuitenkin kiinteistösi myynnin uskomisen kahdelle kiinteistönvälitystoimistolle.

    Se tarjoaa täsmälleen samat edut, eli suuremman taloudellisten ja inhimillisten resurssien saatavuuden toimistoilta ja paremmin harmonisoidun viestintästrategian kuin yksinkertaisessa toimeksiannossa.

    Kun on kyse valinnasta näiden eri toimeksiantotyyppien välillä, erityisesti jos epäröit yksinoikeudellisen ja jaetun yksinoikeudellisen toimeksiannon välillä, on suositeltavaa ottaa yhteyttä suosimaasi toimistoon. Näin se voi ohjata sinut välittäjän luo, jonka kanssa yhteistyötä voidaan tehdä synergian luomiseksi. Moninkertaistat siten voimat parempien tulosten saavuttamiseksi.

    ### Miten myymme kiinteistösi?

    Tiimimme luovat myyntiargumentaation, joka seuraa visuaalista sisältöä (HD-videot ja 360° HD-valokuvat) kaikilla hallitsemillamme kanavilla (verkkosivusto, sosiaalinen media, lehdistökatsaukset jne.). Kun ostaja on kiinnostunut, järjestämme kiinteistön esittelyn yhdessä neuvottelijamme kanssa.

    Tämän prosessin jälkeen, jos asiakas on kiinnostunut kiinteistöstä, laadimme ostotarjouksen hänen ehtoineen, johon liitetään 10% ehdotetusta summasta oleva shekki notaarin nimiin, osoitukseksi hänen vilpittömästä halustaan hankkia kiinteistö. Huomaa, että olemme jatkuvassa yhteydessä myyjään ja ostajaan koko myyntiprosessin ajan. Mikäli hinnasta ja kohteesta päästään sopimukseen, varaamme ajan ruhtinaskunnan notaarille alustavan kauppasopimuksen allekirjoittamista varten. Shekki lunastetaan ennakkomaksuna myyntihintaan.

    Kuten korostimme Monacoon asettumisen osto-oppaassamme, alustavan kauppasopimuksen allekirjoittaminen ei ole pakollista, mutta voi olla tarpeen, erityisesti monacalaisen valtion etuosto-oikeuden yhteydessä. Tämä oikeus koskee kaikkia ennen vuotta 1947 rakennettuja rakennuksia.

    Lopuksi, kun kaikki lykkäävät ehdot on täytetty asetetuissa määräajoissa, on aika kokoontua jälleen notaarin luo virallisen asiakirjan allekirjoittamiseksi, jolloin ostajan on maksettava kokonaisuudessaan kyseisen kiinteistön hintaa vastaava summa vähennettynä ennakkomaksulla, sekä notaarikulut 6% ja välityspalkkio 3% verottomana kiinteistön hinnasta, monacalaisen kiinteistökamarin tariffin mukaisesti. Mikäli jotakin lykkäävää ehtoa ei täytetä, ennakkomaksushekki palautetaan ostajalle ja kauppa katsotaan peruuntuneeksi.

    ### Varojen maksaminen

    Kun asiakirjat on allekirjoitettu notaarin edessä, varat maksetaan sinulle notaaritoimiston toimesta 15 päivän kuluessa, vähennettynä myyjän välityspalkkioilla, jotka on asetettu monacalaisen kiinteistökamarin tariffin mukaisesti 5%:iin verottomana myyntihinnasta.

    Toivomme, että tiedät nyt enemmän kiinteistön myyntiprosessistamme Monacossa.
  BODY
)

article.save!
puts "OK: #{article.slug} (#{article.title.keys.sort.join(', ')})"
