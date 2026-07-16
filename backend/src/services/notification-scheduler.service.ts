import { flushNotificationBatches, sendPendingLeaveReminders, sendTodayLifecycleNotifications } from './notification.service';
import { logger } from '../utils/logger';

let timer: NodeJS.Timeout | undefined;
export function startNotificationScheduler() {
  const schedule = () => {
    const now = new Date();
    const next = new Date(now); next.setMinutes(60, 0, 0);
    timer = setTimeout(async () => {
      try {
        const istHour = Number(new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Kolkata', hour: '2-digit', hour12: false }).format(new Date()));
        await flushNotificationBatches(istHour === 18);
        if (istHour === 9) {
          await sendTodayLifecycleNotifications();
          await sendPendingLeaveReminders();
        }
      }
      catch (error) { logger.error('Notification batch flush failed', {}, error); }
      finally { schedule(); }
    }, next.getTime() - now.getTime());
    timer.unref();
  };
  schedule();
}
export function stopNotificationScheduler() { if (timer) clearTimeout(timer); timer = undefined; }
