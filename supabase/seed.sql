-- TaleemVoice seed — global catalog only.
-- Safe to run once after migrations. Does not create Auth users.

insert into public.platform_settings (id, student_self_registration, institution_self_onboarding)
values (1, true, true)
on conflict (id) do nothing;

insert into public.evaluation_criteria (category, title, description, display_order)
values
  (
    'teaching_methodology',
    'Teaching methodology and clarity',
    'How clearly the teacher explains ideas, uses examples, and structures lessons.',
    1
  ),
  (
    'subject_knowledge',
    'Subject knowledge',
    'How confidently and accurately the teacher handles the subject matter.',
    2
  ),
  (
    'classroom_behaviour',
    'Classroom behaviour and professionalism',
    'Respect, fairness, and professional conduct in the classroom.',
    3
  ),
  (
    'punctuality_responsibility',
    'Punctuality and responsibility',
    'Starting on time, availability, and follow-through on academic duties.',
    4
  ),
  (
    'student_engagement',
    'Student engagement',
    'How well the teacher involves students and encourages participation.',
    5
  ),
  (
    'assessment_fairness',
    'Assessment fairness',
    'Fair tests, assignments, marking, and feedback on student work.',
    6
  ),
  (
    'overall_effectiveness',
    'Overall teaching effectiveness',
    'Overall student judgement of teaching quality for this subject and class.',
    7
  )
on conflict (category) do update
set
  title = excluded.title,
  description = excluded.description,
  display_order = excluded.display_order,
  is_active = true;
