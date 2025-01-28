/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
    app(input) {
        return {
            name: 'dancecam',
            removal: input?.stage === 'production' ? 'retain' : 'remove',
            protect: ['production'].includes(input?.stage),
            home: 'aws',
        };
    },
    async run() {
        const vpc = new sst.aws.Vpc('VPC');

        const cluster = new sst.aws.Cluster('ServerCluster', { vpc });
        cluster.addService('BunServer', {
            loadBalancer: {
                ports: [
                    { listen: '80/http', forward: '3000/http' },
                    { listen: '80/tcp', forward: '3000/tcp' },
                ],
            },
            dev: {
                command: 'bun dev',
                directory: 'server',
            },
        });
    },
});
