/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
    app(input) {
        return {
            name: 'makers-dancecam-server',
            removal: input?.stage === 'production' ? 'retain' : 'remove',
            // protect: ['production'].includes(input?.stage),
            home: 'aws',
        };
    },
    async run() {
        const vpc = new sst.aws.Vpc('DanceVPC');

        const cluster = new sst.aws.Cluster('ServerCluster', { vpc });
        cluster.addService('BunServer', {
            loadBalancer: {
                ports: [{ listen: '80/tcp', forward: '3000/tcp' }],
            },
            dev: {
                command: 'bun dev',
                directory: 'server',
            },
        });
    },
});
