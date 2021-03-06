import { UnavailabilityError } from 'expo-errors';
import ExponentHaptic from './ExponentHaptic';

/**
 * Notification Feedback Type
 * The type of notification feedback generated by a UINotificationFeedbackGenerator object.
 * https://developer.apple.com/documentation/uikit/uinotificationfeedbacktype
 */
export enum NotificationFeedbackType {
  /**
   * A notification feedback type indicating that a task has completed successfully
   */
  Success = 'success',
  /**
   * A notification feedback type indicating that a task has produced a warning
   */
  Warning = 'warning',
  /**
   * A notification feedback type indicating that a task has failed
   */
  Error = 'error',
}

/**
 * Impact Feedback Style
 * The mass of the objects in the collision simulated by a UIImpactFeedbackGenerator object.
 * https://developer.apple.com/documentation/uikit/uiimpactfeedbackstyle
 */
export enum ImpactFeedbackStyle {
  /**
   * A collision between small, light user interface elements
   */
  Light = 'light',
  /**
   * A collision between moderately sized user interface elements
   */
  Medium = 'medium',
  /**
   * A collision between large, heavy user interface elements
   */
  Heavy = 'heavy',
}

/**
 * Triggers notification feedback.
 */
export function notification(type: NotificationFeedbackType = NotificationFeedbackType.Success) {
  if (!ExponentHaptic.notification) {
    throw new UnavailabilityError('Haptic', 'notification');
  }

  return ExponentHaptic.notification(type);
}

/**
 * Triggers impact feedback.
 */
export function impact(style: ImpactFeedbackStyle = ImpactFeedbackStyle.Medium) {
  if (!ExponentHaptic.impact) {
    throw new UnavailabilityError('Haptic', 'impact');
  }

  return ExponentHaptic.impact(style);
}

/**
 * Triggers selection feedback.
 */
export function selection() {
  if (!ExponentHaptic.selection) {
    throw new UnavailabilityError('Haptic', 'selection');
  }

  return ExponentHaptic.selection();
}
