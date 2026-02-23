import '../models/mchat_question.dart';

/// Hardcoded M-CHAT-R question bank.
/// Question wording is reproduced exactly as provided — do not alter.
const List<Map<String, dynamic>> _kRawQuestions = [
  {
    "id": 1,
    "question":
        "If you point at something across the room, does your child look at it?",
    "examples":
        "For example, if you point at a toy or an animal, does your child look at the toy or animal?",
    "risk_when_answer_yes": false,
    "category": "joint_attention",
  },
  {
    "id": 2,
    "question": "Have you ever wondered if your child might be deaf?",
    "examples": "",
    "risk_when_answer_yes": true,
    "category": "hearing_response",
  },
  {
    "id": 3,
    "question": "Does your child play pretend or make-believe?",
    "examples":
        "For example, pretend to drink from an empty cup, pretend to talk on a phone, or pretend to feed a doll or stuffed animal.",
    "risk_when_answer_yes": false,
    "category": "pretend_play",
  },
  {
    "id": 4,
    "question": "Does your child like climbing on things?",
    "examples": "For example, furniture, playground equipment, or stairs.",
    "risk_when_answer_yes": false,
    "category": "motor_activity",
  },
  {
    "id": 5,
    "question":
        "Does your child make unusual finger movements near his or her eyes?",
    "examples":
        "For example, does your child wiggle his or her fingers close to his or her eyes?",
    "risk_when_answer_yes": true,
    "category": "repetitive_behavior",
  },
  {
    "id": 6,
    "question":
        "Does your child point with one finger to ask for something or to get help?",
    "examples": "For example, pointing to a snack or toy that is out of reach.",
    "risk_when_answer_yes": false,
    "category": "communication_request",
  },
  {
    "id": 7,
    "question":
        "Does your child point with one finger to show you something interesting?",
    "examples":
        "For example, pointing to an airplane in the sky or a big truck in the road.",
    "risk_when_answer_yes": false,
    "category": "joint_attention",
  },
  {
    "id": 8,
    "question": "Is your child interested in other children?",
    "examples":
        "For example, does your child watch other children, smile at them, or go to them?",
    "risk_when_answer_yes": false,
    "category": "social_interest",
  },
  {
    "id": 9,
    "question":
        "Does your child show you things by bringing them to you or holding them up for you to see — not to get help, but just to share?",
    "examples":
        "For example, showing you a flower, a stuffed animal, or a toy truck.",
    "risk_when_answer_yes": false,
    "category": "social_sharing",
  },
  {
    "id": 10,
    "question": "Does your child respond when you call his or her name?",
    "examples":
        "For example, does he or she look up, talk or babble, or stop what he or she is doing when you call his or her name?",
    "risk_when_answer_yes": false,
    "category": "name_response",
  },
  {
    "id": 11,
    "question":
        "When you smile at your child, does he or she smile back at you?",
    "examples": "",
    "risk_when_answer_yes": false,
    "category": "social_reciprocity",
  },
  {
    "id": 12,
    "question": "Does your child get upset by everyday noises?",
    "examples":
        "For example, does your child scream or cry to noise such as a vacuum cleaner or loud music?",
    "risk_when_answer_yes": true,
    "category": "sensory_sensitivity",
  },
  {
    "id": 13,
    "question": "Does your child walk?",
    "examples": "",
    "risk_when_answer_yes": false,
    "category": "motor_development",
  },
  {
    "id": 14,
    "question":
        "Does your child look you in the eye when you are talking to him or her, playing with him or her, or dressing him or her?",
    "examples": "",
    "risk_when_answer_yes": false,
    "category": "eye_contact",
  },
  {
    "id": 15,
    "question": "Does your child try to copy what you do?",
    "examples":
        "For example, wave bye-bye, clap, or make a funny noise when you do.",
    "risk_when_answer_yes": false,
    "category": "imitation",
  },
  {
    "id": 16,
    "question":
        "If you turn your head to look at something, does your child look around to see what you are looking at?",
    "examples": "",
    "risk_when_answer_yes": false,
    "category": "joint_attention",
  },
  {
    "id": 17,
    "question": "Does your child try to get you to watch him or her?",
    "examples":
        "For example, does your child look at you for praise, or say 'look' or 'watch me'?",
    "risk_when_answer_yes": false,
    "category": "attention_sharing",
  },
  {
    "id": 18,
    "question":
        "Does your child understand when you tell him or her to do something?",
    "examples":
        "For example, if you don't point, can your child understand 'put the book on the chair' or 'bring me the blanket'?",
    "risk_when_answer_yes": false,
    "category": "language_comprehension",
  },
  {
    "id": 19,
    "question":
        "If something new happens, does your child look at your face to see how you feel about it?",
    "examples":
        "For example, if he or she hears a strange or funny noise, or sees a new toy, will he or she look at your face?",
    "risk_when_answer_yes": false,
    "category": "social_reference",
  },
  {
    "id": 20,
    "question": "Does your child like movement activities?",
    "examples": "For example, being swung or bounced on your knee.",
    "risk_when_answer_yes": false,
    "category": "sensory_seeking",
  },
];

/// All 20 M-CHAT-R questions as typed models.
final List<MchatQuestion> kMchatQuestions = _kRawQuestions
    .map(MchatQuestion.fromJson)
    .toList();
