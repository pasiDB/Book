import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../models/book_model.dart';
import '../../core/constants/app_constants.dart';

abstract class BookRemoteDataSource {
  Future<List<BookModel>> getBooksByTopic(String topic);
  Future<List<BookModel>> getBooksByTopicWithPagination(String topic,
      {int limit = 10, int offset = 0});
  Future<List<BookModel>> searchBooks(String query);
  Future<BookModel?> getBookById(int id);
  Future<List<BookModel>> getBooksByPage(int page);
  Future<String> getBookContent(String textUrl);
  Future<String> getBookContentByGutenbergId(int gutenbergId);
}

class BookRemoteDataSourceImpl implements BookRemoteDataSource {
  final Dio dio;

  BookRemoteDataSourceImpl(this.dio);

  @override
  Future<List<BookModel>> getBooksByTopic(String topic) async {
    try {
      final response = await dio.get('${AppConstants.topicEndpoint}$topic');
      final apiResponse = ApiResponseModel.fromJson(response.data);
      return apiResponse.results;
    } catch (e) {
      throw Exception('Failed to fetch books by topic: $e');
    }
  }

  @override
  Future<List<BookModel>> getBooksByTopicWithPagination(String topic,
      {int limit = 10, int offset = 0}) async {
    try {
      // Use the original endpoint without pagination parameters
      final response = await dio.get('${AppConstants.topicEndpoint}$topic');
      final apiResponse = ApiResponseModel.fromJson(response.data);
      final allBooks = apiResponse.results;

      // Implement pagination on client side
      final startIndex = offset;
      final endIndex = (startIndex + limit < allBooks.length)
          ? startIndex + limit
          : allBooks.length;

      if (startIndex < allBooks.length) {
        return allBooks.sublist(startIndex, endIndex);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch books by topic with pagination: $e');
    }
  }

  @override
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      final response = await dio.get('${AppConstants.searchEndpoint}$query');
      final apiResponse = ApiResponseModel.fromJson(response.data);
      return apiResponse.results;
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  @override
  Future<BookModel?> getBookById(int id) async {
    try {
      final response = await dio.get('${AppConstants.booksEndpoint}$id');
      return BookModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch book by id: $e');
    }
  }

  @override
  Future<List<BookModel>> getBooksByPage(int page) async {
    try {
      final response =
          await dio.get('${AppConstants.booksEndpoint}?page=$page');
      final apiResponse = ApiResponseModel.fromJson(response.data);
      return apiResponse.results;
    } catch (e) {
      throw Exception('Failed to fetch books by page: $e');
    }
  }

  @override
  Future<String> getBookContent(String contentUrl) async {
    print('[RemoteDataSource] Fetching book content from: $contentUrl');
    try {
      final response = await dio.get(contentUrl);
      String content = response.data.toString();
      print(
          '[RemoteDataSource] Book content fetched, length: ${content.length}');
      // If it's HTML content, try to extract text
      if (contentUrl.contains('text/html') || content.contains('<html>')) {
        content = _extractTextFromHtml(content);
      }
      return content;
    } catch (e) {
      print('[RemoteDataSource] Error fetching book content: $e');
      // If direct fetch fails due to CORS, try using a CORS proxy
      try {
        final corsProxyUrl =
            'https://api.allorigins.win/raw?url=${Uri.encodeComponent(contentUrl)}';
        final response = await dio.get(corsProxyUrl);
        String content = response.data.toString();
        print(
            '[RemoteDataSource] Book content fetched via CORS proxy, length: ${content.length}');
        if (contentUrl.contains('text/html') || content.contains('<html>')) {
          content = _extractTextFromHtml(content);
        }
        return content;
      } catch (proxyError) {
        print(
            '[RemoteDataSource] Error fetching book content via CORS proxy: $proxyError');
        // If both direct and proxy fail, try alternative CORS proxies
        try {
          final alternativeProxyUrl =
              'https://cors-anywhere.herokuapp.com/${Uri.encodeComponent(contentUrl)}';
          final response = await dio.get(alternativeProxyUrl);
          String content = response.data.toString();
          print(
              '[RemoteDataSource] Book content fetched via alternative proxy, length: ${content.length}');
          if (contentUrl.contains('text/html') || content.contains('<html>')) {
            content = _extractTextFromHtml(content);
          }
          return content;
        } catch (alternativeError) {
          print(
              '[RemoteDataSource] Error fetching book content via alternative proxy: $alternativeError');
          return _generateFallbackContent(contentUrl);
        }
      }
    }
  }

  @override
  Future<String> getBookContentByGutenbergId(int gutenbergId) async {
    print(
        '[RemoteDataSource] Fetching book content by Gutenberg ID: $gutenbergId');
    // Construct the Project Gutenberg URL for the specific book
    final gutenbergUrl =
        'https://www.gutenberg.org/cache/epub/$gutenbergId/pg$gutenbergId.txt';
    final List<String> proxyUrls = [
      gutenbergUrl, // Direct fetch
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(gutenbergUrl)}',
      'https://cors-anywhere.herokuapp.com/${Uri.encodeComponent(gutenbergUrl)}',
      'https://thingproxy.freeboard.io/fetch/${Uri.encodeComponent(gutenbergUrl)}',
      'https://corsproxy.io/?${Uri.encodeComponent(gutenbergUrl)}',
    ];
    for (String url in proxyUrls) {
      try {
        final response = await dio.get(
          url,
          options: Options(
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Accept':
                  'text/plain,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.5',
              'Accept-Encoding': 'gzip, deflate',
              'Connection': 'keep-alive',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        if (response.statusCode == 200 && response.data != null) {
          String content = response.data.toString();
          print(
              '[RemoteDataSource] Book content fetched from $url, length: ${content.length}');
          content = _cleanGutenbergContent(content);
          if (content.length > 1000) {
            return content;
          }
        }
      } catch (e) {
        print('[RemoteDataSource] Error fetching book content from $url: $e');
        continue;
      }
    }
    print('[RemoteDataSource] All proxies failed, returning fallback content.');
    return _generateFallbackContent(gutenbergUrl);
  }

  String _extractTextFromHtml(String html) {
    // Remove script and style tags first
    String text = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove remaining HTML tags
        .replaceAll('&nbsp;', ' ') // Replace HTML entities
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '...')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&lsquo;', ''')
        .replaceAll('&rsquo;', ''');

    // Clean up extra whitespace and normalize line breaks
    text = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Normalize paragraph breaks
        .trim();

    // If the text is too short, it might not be valid content
    if (text.length < 100) {
      return _generateFallbackContent('HTML content extraction failed');
    }

    return text;
  }

  String _cleanGutenbergContent(String content) {
    // Remove Project Gutenberg header and footer
    String cleanedContent = content;

    // Remove the Project Gutenberg header (everything before "*** START OF")
    final startIndex = cleanedContent.indexOf('*** START OF');
    if (startIndex != -1) {
      cleanedContent = cleanedContent.substring(startIndex);
    }

    // Remove the Project Gutenberg footer (everything after "*** END OF")
    final endIndex = cleanedContent.indexOf('*** END OF');
    if (endIndex != -1) {
      cleanedContent = cleanedContent.substring(0, endIndex);
    }

    // Clean up extra whitespace and normalize line breaks
    cleanedContent = cleanedContent
        .replaceAll(RegExp(r'\r\n'), '\n') // Normalize line endings
        .replaceAll(RegExp(r'\r'), '\n') // Handle old Mac line endings
        .replaceAll(
            RegExp(r'\n\s*\n\s*\n'), '\n\n') // Remove excessive line breaks
        .trim();

    // If the content is too short after cleaning, return original
    if (cleanedContent.length < 100) {
      return content;
    }

    return cleanedContent;
  }

  String _generateFallbackContent(String contentUrl) {
    // Try to provide sample content for known books
    if (contentUrl.contains('2701')) {
      return _getMobyDickSample();
    } else if (contentUrl.contains('84')) {
      return _getFrankensteinSample();
    } else if (contentUrl.contains('1342')) {
      return _getPrideAndPrejudiceSample();
    }

    return '''
Chapter 1: Introduction

This book is available from Project Gutenberg, but the content couldn't be loaded directly due to network restrictions.

You can read this book by visiting the original source:
$contentUrl

Alternatively, you can download the book in various formats from Project Gutenberg's website.

About this book:
- This is a public domain book from Project Gutenberg
- The book is available in multiple formats including text, HTML, and EPUB
- You can download it for offline reading

Features of this reader:
- Font size adjustment (use the Tt button in the top right)
- Bookmarking (coming soon)
- Reading progress tracking (coming soon)
- Offline reading (coming soon)

To read the full content of this book, please visit the Project Gutenberg website or download the book file directly.

Note: The app is trying to load content using a CORS proxy. If you continue to see this message, the book content may be temporarily unavailable or the proxy service may be down. You can try refreshing the page or visiting the Project Gutenberg website directly.
    ''';
  }

  String _getMobyDickSample() {
    return '''
MOBY-DICK; or, THE WHALE.

By Herman Melville

CHAPTER 1. Loomings.

Call me Ishmael. Some years ago—never mind how long precisely—having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation. Whenever I find myself growing grim about the mouth; whenever it is a damp, drizzly November in my soul; whenever I find myself involuntarily pausing before coffin warehouses, and bringing up the rear of every funeral I meet; and especially whenever my hypos get such an upper hand of me, that it requires a strong moral principle to prevent me from deliberately stepping into the street, and methodically knocking people's hats off—then, I account it high time to get to sea as soon as I can. This is my substitute for pistol and ball. With a philosophical flourish Cato throws himself upon his sword; I quietly take to the ship. There is nothing surprising in this. If they but knew it, almost all men in their degree, some time or other, cherish very nearly the same feelings towards the ocean with me.

There now is your insular city of the Manhattoes, belted round by wharves as Indian isles by coral reefs—commerce surrounds it with her surf. Right and left, the streets take you waterward. Its extreme downtown is the battery, where that noble mole is washed by waves, and cooled by breezes, which a few hours previous were out of sight of land. Look at the crowds of water-gazers there.

Circumambulate the city of a dreamy Sabbath afternoon. Go from Corlears Hook to Coenties Slip, and from thence, by Whitehall, northward. What do you see?—Posted like silent sentinels all around the town, stand thousands upon thousands of mortal men fixed in ocean reveries. Some leaning against the spiles; some seated upon the pier-heads; some looking over the bulwarks of ships from China; some high aloft in the rigging, as if striving to get a still better seaward peep. But these are all landsmen; of week days pent up in lath and plaster—tied to counters, nailed to benches, clinched to desks. How then is this? Are the green fields gone? What do they here?

But look! here come more crowds, pacing straight for the water, and seemingly bound for a dive. Strange! Nothing will content them but the extremest limit of the land; loitering under the shady lee of yonder warehouses will not suffice. No. They must get just as nigh the water as they possibly can without falling in. And there they stand—miles of them—leagues. Inlanders all, they come from lanes and alleys, streets and avenues—north, east, south, and west. Yet here they all unite. Tell me, does the magnetic virtue of the needles of the compasses of all those ships attract them thither?

Once more. Say you are in the country; in some high land of lakes. Take almost any path you please, and ten to one it carries you down in a dale, and leaves you there by a pool in the stream. There is magic in it. Let the most absent-minded of men be plunged in his deepest reveries—stand that man on his legs, set his feet a-going, and he will infallibly lead you to water, if water there be in all that region. Should you ever be athirst in the great American desert, try this experiment, if your caravan happen to be supplied with a metaphysical professor. Yes, as every one knows, meditation and water are wedded for ever.

But here is an artist. He desires to paint you the dreamiest, shadiest, quietest, most enchanting bit of romantic landscape in all the valley of the Saco. What is the chief element he employs? There stand his trees, each with a hollow trunk, as if a hermit and a crucifix were within; and here sleeps his meadow, and there sleep his cattle; and up from yonder cottage goes a sleepy smoke. Deep into distant woodlands winds a mazy way, reaching to overlapping spurs of mountains bathed in their hill-side blue. But though the picture lies thus tranced, and though this pine-tree shakes down its sighs like leaves upon this shepherd's head, yet all were vain, unless the shepherd's eye were fixed upon the magic stream before him. Go visit the Prairies in June, when for scores on scores of miles you wade knee-deep among Tiger-lilies—what is the one charm wanting?—Water—there is not a drop of water there! Were Niagara but a cataract of sand, would you travel your thousand miles to see it? Why did the poor poet of Tennessee, upon suddenly receiving two handfuls of silver, deliberate whether to buy him a coat, which he sadly needed, or invest his money in a pedestrian trip to Rockaway Beach? Why is almost every robust healthy boy with a robust healthy soul in him, at some time or other crazy to go to sea? Why upon your first voyage as a passenger, did you yourself feel such a mystical vibration, when first told that you and your ship were now out of sight of land? Why did the old Persians hold the sea holy? Why did the Greeks give it a separate deity, and own brother of Jove? Surely all this is not without meaning. And still deeper the meaning of that story of Narcissus, who because he could not grasp the tormenting, mild image he saw in the fountain, plunged into it and was drowned. But that same image, we ourselves see in all rivers and oceans. It is the image of the ungraspable phantom of life; and this is the key to it all.

Now, when I say that I am in the habit of going to sea whenever I begin to grow hazy about the eyes, and begin to be over conscious of my lungs, I do not mean to have it inferred that I ever go to sea as a passenger. For to go as a passenger you must needs have a purse, and a purse is but a rag unless you have something in it. Besides, passengers get sea-sick—grow quarrelsome—don't sleep of nights—do not enjoy themselves much, as a general thing;—no, I never go as a passenger; nor, though I am something of a salt, do I ever go to sea as a Commodore, or a Captain, or a Cook. I abandon the glory and distinction of such offices to those who like them. For my part, I abominate all honorable respectable toils, trials, and tribulations of every kind whatsoever. It is quite as much as I can do to take care of myself, without taking care of ships, barques, brigs, schooners, and what not. And as for going as cook,—though I confess there is considerable glory in that, a cook being a sort of officer on ship-board—yet, somehow, I never fancied broiling fowls;—though once broiled, judiciously buttered, and judgmatically salted and peppered, there is no one who will speak more respectfully, not to say reverentially, of a broiled fowl than I will. It is out of the idolatrous dotings of the old Egyptians upon broiled ibis and roasted river horse, that you see the mummies of those creatures in their huge bake-houses the pyramids.

No, when I go to sea, I go as a simple sailor, right before the mast, plumb down into the forecastle, aloft there to the royal mast-head. True, they rather order me about some, and make me jump from spar to spar, like a grasshopper in a May meadow. And at first, this sort of thing is unpleasant enough. It touches one's sense of honor, particularly if you come of an old established family in the land, the Van Rensselaers, or Randolphs, or Hardicanutes. And more than all, if just previous to putting your hand into the tar-pot, you have been lording it as a country schoolmaster, making the tallest boys stand in awe of you. The transition is a keen one, I assure you, from a schoolmaster to a sailor, and requires a strong decoction of Seneca and the Stoics to enable you to grin and bear it. But even this wears off in time.

What of it, if some old hunks of a sea-captain orders me to get a broom and sweep down the decks? What does that indignity amount to, weighed, I mean, in the scales of the New Testament? Do you think the archangel Gabriel thinks anything the less of me, because I promptly and respectfully obey that old hunks in that particular instance? Who ain't a slave? Tell me that. Well, then, however the old sea-captains may order me about—however they may thump and punch me about, I have the satisfaction of knowing that it is all right; that everybody else is one way or other served in much the same way—either in a physical or metaphysical point of view, that is; and so the universal thump is passed round, and all hands should rub each other's shoulder-blades, and be content.

Again, I always go to sea as a sailor, because they make a point of paying me for my trouble, whereas they never pay passengers a single penny that I ever heard of. On the contrary, passengers themselves must pay. And there is all the difference in the world between paying and being paid. The act of paying is perhaps the most uncomfortable infliction that the two orchard thieves entailed upon us. But being paid,—what will compare with it? The urbane activity with which a man receives money is really marvellous, considering that we so earnestly believe money to be the root of all earthly ills, and that on no account can a monied man enter heaven. Ah! how cheerfully we consign ourselves to perdition!

Finally, I always go to sea as a sailor, because of the wholesome exercise and pure air of the fore-castle deck. For as in this world, head winds are far more prevalent than winds from astern (that is, if you never violate the Pythagorean maxim), so for the most part the Commodore on the quarter-deck gets his atmosphere at second hand from the sailors on the forecastle. He thinks he breathes it first; but not so. In much the same way do the commonalty lead their leaders in many other things, at the same time that the leaders little suspect it. But wherefore it was that after having repeatedly smelt the sea as a merchant sailor, I should now take it into my head to go on a whaling voyage; this the invisible police officer of the Fates, who has the constant surveillance of me, and secretly dogs me, and influences me in some unaccountable way—he can better answer than any one else. And, doubtless, my going on this whaling voyage, formed part of the grand programme of Providence that was drawn up a long time ago. It came in as a sort of brief interlude and solo between more extensive performances. I take it that this part of the bill must have run something like this:

"Grand Contested Election for the Presidency of the United States.
"WHALING VOYAGE BY ONE ISHMAEL.
"BLOODY BATTLE IN AFFGHANISTAN."

Though I cannot tell why it was exactly that those stage managers, the Fates, put me down for this shabby part of a whaling voyage, when others were set down for magnificent parts in high tragedies, and short and easy parts in genteel comedies, and jolly parts in farces—though I cannot tell why this was exactly; yet, now that I recall all the circumstances, I think I can see a little into the springs and motives which being cunningly presented to me under various disguises, induced me to set about performing the part I did, besides cajoling me into the delusion that it was a choice resulting from my own unbiased freewill and discriminating judgment.

Chief among these motives was the overwhelming idea of the great whale himself. Such a portentous and mysterious monster roused all my curiosity. Then the wild and distant seas where he rolled his island bulk; the undeliverable, nameless perils of the whale; these, with all the attending marvels of a thousand Patagonian sights and sounds, helped to sway me to my wish. With other men, perhaps, such things would not have been inducements; but as for me, I am tormented with an everlasting itch for things remote. I love to sail forbidden seas, and land on barbarous coasts. Not ignoring what is good, I am quick to perceive a horror, and could still be social with it—would they let me—since it is but well to be on friendly terms with all the inmates of the place one lodges in.

By reason of these things, then, the whaling voyage was welcome; the great flood-gates of the wonder-world swung open, and in the wild conceits that swayed me to my purpose, two and two there floated into my inmost soul, endless processions of the whale, and, mid most of them all, one grand hooded phantom, like a snow hill in the air.

[This is a sample of the beginning of Moby Dick. The full text is available at Project Gutenberg.]
    ''';
  }

  String _getFrankensteinSample() {
    return '''
FRANKENSTEIN; OR, THE MODERN PROMETHEUS.

By Mary Wollstonecraft Shelley

LETTER I.

To Mrs. Saville, England.

St. Petersburgh, Dec. 11th, 17—.

You will rejoice to hear that no disaster has accompanied the commencement of an enterprise which you have regarded with such evil forebodings. I arrived here yesterday, and my first task is to assure my dear sister of my welfare and increasing confidence in the success of my undertaking.

I am already far north of London, and as I walk in the streets of Petersburgh, I feel a cold northern breeze play upon my cheeks, which braces my nerves and fills me with delight. Do you understand this feeling? This breeze, which has travelled from the regions towards which I am advancing, gives me a foretaste of those icy climes. Inspirited by this wind of promise, my daydreams become more fervent and vivid. I try in vain to be persuaded that the pole is the seat of frost and desolation; it ever presents itself to my imagination as the region of beauty and delight. There, Margaret, the sun is for ever visible, its broad disk just skirting the horizon and diffusing a perpetual splendour. There—for with your leave, my sister, I will put some trust in preceding navigators—there snow and frost are banished; and, sailing over a calm sea, we may be wafted to a land surpassing in wonders and in beauty every region hitherto discovered on the habitable globe. Its productions and features may be without example, as the phenomena of the heavenly bodies undoubtedly are in those undiscovered solitudes. What may not be expected in a country of eternal light? I may there discover the wondrous power which attracts the needle and may regulate a thousand celestial observations that require only this voyage to render their seeming eccentricities consistent for ever. I shall satiate my ardent curiosity with the sight of a part of the world never before visited, and may tread a land never before imprinted by the foot of man. These are my enticements, and they are sufficient to conquer all fear of danger or death and to induce me to commence this laborious voyage with the joy a child feels when he embarks in a little boat, with his holiday mates, on an expedition of discovery up his native river. But supposing all these conjectures to be false, you cannot contest the inestimable benefit which I shall confer on all mankind, to the last generation, by discovering a passage near the pole to those countries, to reach which at present so many months are requisite; or by ascertaining the secret of the magnet, which, if at all possible, can only be effected by an undertaking such as mine.

These reflections have dispelled the agitation with which I began my letter, and I feel my heart glow with an enthusiasm which elevates me to heaven, for nothing contributes so much to tranquillize the mind as a steady purpose—a point on which the soul may fix its intellectual eye. This expedition has been the favourite dream of my early years. I have read with ardour the accounts of the various voyages which have been made in the prospect of arriving at the North Pacific Ocean through the seas which surround the pole. You may remember that a history of all the voyages made for purposes of discovery composed the whole of our good Uncle Thomas' library. My education was neglected, yet I was passionately fond of reading. These volumes were my study day and night, and my familiarity with them increased that regret which I had felt, as a child, on learning that my father's dying injunction had forbidden my uncle to allow me to embark in a seafaring life.

These visions faded when I perused, for the first time, those poets whose effusions entranced my soul and lifted it to heaven. I also became a poet and for one year lived in a paradise of my own creation; I imagined that I also might obtain a niche in the temple where the names of Homer and Shakespeare are consecrated. You are well acquainted with my failure and how heavily I bore the disappointment. But just at that time I inherited the fortune of my cousin, and my thoughts were turned into the channel of their earlier bent.

Six years have passed since I resolved on my present undertaking. I can, even now, remember the hour from which I dedicated myself to this great enterprise. I commenced by inuring my body to hardship. I accompanied the whale-fishers on several expeditions to the North Sea; I voluntarily endured cold, famine, thirst, and want of sleep; I often worked harder than the common sailors during the day and devoted my nights to the study of mathematics, the theory of medicine, and those branches of physical science from which a naval adventurer might derive the greatest practical advantage. Twice I actually hired myself as an under-mate in a Greenland whaler, and acquitted myself to admiration. I must own I felt a little proud when my captain offered me the second dignity in the vessel and entreated me to remain with the greatest earnestness, so valuable did he consider my services.

And now, dear Margaret, do I not deserve to accomplish some great purpose? My life might have been passed in ease and luxury, but I preferred glory to every enticement that wealth placed in my path. Oh, that some encouraging voice would answer in the affirmative! My courage and my resolution is firm; but my hopes fluctuate, and my spirits are often depressed. I am about to proceed on a long and difficult voyage, the emergencies of which will demand all my fortitude: I am required not only to raise the spirits of others, but sometimes to sustain my own, when theirs are failing.

This is the most favourable period for travelling in Russia. They fly quickly over the snow in their sledges; the motion is pleasant, and, in my opinion, far more agreeable than that of an English stagecoach. The cold is not excessive, if you are wrapped in furs—a dress which I have already adopted, for there is a great difference between walking the deck and remaining seated motionless for hours, when no exercise prevents the blood from actually freezing in your veins. I have no ambition to lose my life on the post-road between St. Petersburgh and Archangel.

I shall depart for the latter town in a fortnight or three weeks; and my intention is to hire a ship there, which can easily be done by paying the insurance for the owner, and to engage as many sailors as I think necessary among those who are accustomed to the whale-fishing. I do not intend to sail until the month of June; and when shall I return? Ah, dear sister, how can I answer this question? If I succeed, many, many months, perhaps years, will pass before you and I may meet. If I fail, you will see me again soon, or never.

Farewell, my dear, excellent Margaret. Heaven shower down blessings on you, and save me, that I may again and again testify my gratitude for all your love and kindness.

Your affectionate brother,
R. Walton

[This is a sample of the beginning of Frankenstein. The full text is available at Project Gutenberg.]
    ''';
  }

  String _getPrideAndPrejudiceSample() {
    return '''
PRIDE AND PREJUDICE

By Jane Austen

Chapter 1

It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.

However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.

"My dear Mr. Bennet," said his lady to him one day, "have you heard that Netherfield Park is let at last?"

Mr. Bennet replied that he had not.

"But it is," returned she; "for Mrs. Long has just been here, and she told me all about it."

Mr. Bennet made no answer.

"Do you not want to know who has taken it?" cried his wife impatiently.

"YOU want to tell me, and I have no objection to hearing it."

This was invitation enough.

"Why, my dear, you must know, Mrs. Long says that Netherfield is taken by a young man of large fortune from the north of England; that he came down on Monday in a chaise and four to see the place, and was so much delighted with it, that he agreed with Mr. Morris immediately; that he is to take possession before Michaelmas, and some of his servants are to be in the house by the end of next week."

"What is his name?"

"Bingley."

"Is he married or single?"

"Oh! Single, my dear, to be sure! A single man of large fortune; four or five thousand a year. What a fine thing for our girls!"

"How so? How can it affect them?"

"My dear Mr. Bennet," replied his wife, "how can you be so tiresome! You must know that I am thinking of his marrying one of them."

"Is that his design in settling here?"

"Design! Nonsense, how can you talk so! But it is very likely that he may fall in love with one of them, and therefore you must visit him as soon as he comes."

"I see no occasion for that. You and the girls may go, or you may send them by themselves, which perhaps will be still better, for as you are as handsome as any of them, Mr. Bingley may like you the best of the party."

"My dear, you flatter me. I certainly HAVE had my share of beauty, but I do not pretend to be anything extraordinary now. When a woman has five grown-up daughters, she ought to give over thinking of her own beauty."

"In such cases, a woman has not often much beauty to think of."

"But, my dear, you must indeed go and see Mr. Bingley when he comes into the neighbourhood."

"It is more than I engage for, I assure you."

"But consider your daughters. Only think what an establishment it would be for one of them. Sir William and Lady Lucas are determined to go, merely on that account, for in general, you know, they visit no newcomers. Indeed you must go, for it will be impossible for US to visit him if you do not."

"You are over-scrupulous, surely. I dare say Mr. Bingley will be very glad to see you; and I will send a few lines by you to assure him of my hearty consent to his marrying whichever he chooses of the girls; though I must throw in a good word for my little Lizzy."

"I desire you will do no such thing. Lizzy is not a bit better than the others; and I am sure she is not half so handsome as Jane, nor half so good-humoured as Lydia. But you are always giving HER the preference."

"They have none of them much to recommend them," replied he; "they are all silly and ignorant like other girls; but Lizzy has something more of quickness than her sisters."

"Mr. Bennet, how CAN you abuse your own children in such a way? You take delight in vexing me. You have no compassion for my poor nerves."

"You mistake me, my dear. I have a high respect for your nerves. They are my old friends. I have heard you mention them with consideration these last twenty years at least."

Mr. Bennet was so odd a mixture of quick parts, sarcastic humour, reserve, and caprice, that the experience of three-and-twenty years had been insufficient to make his wife understand his character. HER mind was less difficult to develop. She was a woman of mean understanding, little information, and uncertain temper. When she was discontented, she fancied herself nervous. The business of her life was to get her daughters married; its solace was visiting and news.

[This is a sample of the beginning of Pride and Prejudice. The full text is available at Project Gutenberg.]
    ''';
  }
}
