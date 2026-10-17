import Foundation
import FoundationModels

@Generable
nonisolated enum VoiceRepeatRule { case daily, weekly }

@Generable
nonisolated struct VoiceCapturedTask {
  @Guide(
    description: "Concise actionable task explicitly requested by the user, in their language.")
  var text: String
  @Guide(
    description:
      "Exact quote of the action in the transcript. Never invent tasks from notes or event titles.")
  var source: String
}

@Generable
nonisolated struct VoiceBlockResult {
  @Guide(
    description:
      "Concise note or event title in the user's language, not the raw transcript. Remove commands, filler and schedule details represented in other components. Empty for task-only requests."
  )
  var text: String
  @Guide(
    description:
      "Exact quote containing the note or event title. Nil when no text content was provided; never quote a task just to create a second component."
  )
  var textSource: String?
  @Guide(
    description:
      "Short actionable checklist items in the user's language. Remove filler, creation commands, and scheduling phrases. Empty if there are no tasks."
  )
  var tasks: [VoiceCapturedTask]
  @Guide(
    description:
      "Explicit or relative start date, exactly yyyy-MM-dd. Resolve relative dates from today. Nil if no date was mentioned."
  )
  var startDate: String?
  @Guide(
    description:
      "Exact quote of the explicit date, relative date, or weekday. Nil without a date mention. Every day/week alone is not a start date."
  )
  var dateSource: String?
  @Guide(
    description:
      "Explicit start time, exactly HH:mm in 24-hour local time. Nil if no time was mentioned.")
  var startTime: String?
  @Guide(
    description:
      "Exact quote of the stated clock time. Nil without a time mention. A date, task, or recurrence is not a time."
  )
  var timeSource: String?
  @Guide(
    description:
      "Daily or weekly only with an explicit every/each day, week, or weekday phrase (or its equivalent in the user's language). Otherwise nil. Dates and times alone never imply repetition."
  )
  var recurrence: VoiceRepeatRule?
  @Guide(
    description:
      "Exact quote of the every/each day, week, or weekday phrase. Nil when recurrence was not explicitly requested."
  )
  var recurrenceSource: String?
}
