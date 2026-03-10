import { serviceClients, Session, cloudApi } from '@yandex-cloud/nodejs-sdk';
import { CronExpressionParser } from 'cron-parser';

const {
  compute: {
    instance_service: {
      GetInstanceRequest,
      StartInstanceRequest,
      StopInstanceRequest,
    },
    instance: {
      Instance_Status,
    },
  },
} = cloudApi;

function shouldBeRunning(vm) {
  if (vm.mode === 'always') return true;

  if (vm.mode === 'scheduled') {
    const now = new Date();

    const interval = CronExpressionParser.parse(vm.cronStart, {
      currentDate: now,
      tz: vm.tz || 'UTC',
    });

    const lastStart = interval.prev().toDate();
    const expiry = new Date(lastStart.getTime() + (vm.durationHours * 60 * 60 * 1000));

    return now >= lastStart && now < expiry;
  }

  return false;
}

export const handler = async function (event, context) {
  const payload = JSON.parse(event.messages[0].details.payload);
  const vms = payload.vms || [];

  const session = new Session({ iamToken: context.token.access_token });
  const instanceClient = session.client(serviceClients.InstanceServiceClient);

  const results = await Promise.all(vms.map(async (vm) => {
    const targetStatus = shouldBeRunning(vm) ? Instance_Status.RUNNING : Instance_Status.STOPPED;

    const currentState = await instanceClient.get(GetInstanceRequest.fromPartial({
      instanceId: vm.id,
    }));
    const currentStatus = currentState.status;

    if (currentStatus === Instance_Status.STOPPED && targetStatus === Instance_Status.RUNNING) {
      await instanceClient.start(StartInstanceRequest.fromPartial({
        instanceId: vm.id,
      }));
    }

    if (currentStatus === Instance_Status.RUNNING && targetStatus === Instance_Status.STOPPED) {
      await instanceClient.stop(StopInstanceRequest.fromPartial({
        instanceId: vm.id,
      }));
    }

    return {
      id: vm.id,
      targetStatus: targetStatus,
      currentStatus: currentStatus,
    };
  }));

  return {
    statusCode: 200,
    body: results,
  };
};
