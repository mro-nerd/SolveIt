import '../models/stimulus.dart';

/// The predefined stimuli used in the Emotion Response Assessment.
///
/// 6 rounds: 2 × happy, 2 × surprise, 2 × sad.
/// Each round lasts 5 seconds.
const List<Stimulus> kStimuliRounds = [
  Stimulus(
    id: 'funny_face',
    title: 'Funny Faces!',
    emoji: '🤪😂🤣',
    description: 'Look at these silly faces!',
    expectedEmotion: ExpectedEmotion.happy,
    imagePath: 'assets/images/stimuli/funny_faces.png',
  ),
  Stimulus(
    id: 'surprise_pop',
    title: 'Pop!',
    emoji: '🎈💥🎆',
    description: 'Wow, what was that?!',
    expectedEmotion: ExpectedEmotion.surprise,
    imagePath: 'assets/images/stimuli/surprise_pop.png',
  ),
  Stimulus(
    id: 'sad_puppy',
    title: 'Oh no…',
    emoji: '🐶😢💔',
    description: 'The puppy is feeling sad…',
    expectedEmotion: ExpectedEmotion.sad,
    imagePath: 'assets/images/stimuli/sad_puppy.png',
  ),
  Stimulus(
    id: 'party_time',
    title: 'Party Time!',
    emoji: '🎉🥳🎊',
    description: 'It\'s time to celebrate!',
    expectedEmotion: ExpectedEmotion.happy,
    imagePath: 'assets/images/stimuli/party_time.png',
  ),
  Stimulus(
    id: 'peek_a_boo',
    title: 'Peek-a-Boo!',
    emoji: '👻🫣😲',
    description: 'Boo! Did I surprise you?',
    expectedEmotion: ExpectedEmotion.surprise,
    imagePath: 'assets/images/stimuli/peek_a_boo.png',
  ),
  Stimulus(
    id: 'sad_kitty',
    title: 'Poor kitty…',
    emoji: '🐱😿🥺',
    description: 'The little kitty is crying…',
    expectedEmotion: ExpectedEmotion.sad,
    imagePath: 'assets/images/stimuli/sad_kitty.png',
  ),
];
