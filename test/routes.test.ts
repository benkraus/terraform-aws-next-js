import * as fs from 'fs';
import * as path from 'path';
import { parse as parseJSON } from 'hjson';
import { ConfigOutput } from 'tf-next/src/types';
import { CloudFrontResultResponse } from 'aws-lambda';
import {
  generateSAM,
  LambdaSAM,
  generateProxySAM,
  ProxySAM,
  normalizeCloudFrontHeaders,
  ConfigLambda,
} from '@dealmore/sammy';

const pathToFixtures = path.join(__dirname, 'fixtures');
const pathToProxyPackage = path.join(__dirname, '../packages/proxy/dist.zip');

interface ProbeFile {
  probes: {
    path: string;
    mustContain?: string;
    status?: number;
    statusDescription?: string;
    responseHeaders?: Record<string, string>;
  }[];
}

describe('Test proxy config', () => {
  for (const fixture of fs.readdirSync(pathToFixtures)) {
    describe(`Testing fixture: ${fixture}`, () => {
      const pathToFixture = path.join(pathToFixtures, fixture);
      let config: ConfigOutput;
      let probeFile: ProbeFile;
      let lambdaSAM: LambdaSAM;
      let proxySAM: ProxySAM;

      beforeAll(async () => {
        // Get the config
        config = require(path.join(
          pathToFixture,
          '.next-tf/config.json'
        )) as ConfigOutput;

        // Get the probes
        probeFile = parseJSON(
          fs
            .readFileSync(path.join(pathToFixture, 'probes.json'))
            .toString('utf-8')
        ) as ProbeFile;

        // Generate SAM for SSR (Lambda)
        const lambdas: Record<string, ConfigLambda> = {};
        for (const [key, lambda] of Object.entries(config.lambdas)) {
          lambdas[key] = {
            ...lambda,
            route: undefined,
            routes: {
              ApiRoot: `${lambda.route}/`,
              Api: `${lambda.route}/{proxy+}`,
            },
            memorySize: 1024,
          };
        }

        lambdaSAM = await generateSAM({
          lambdas,
          cwd: path.join(pathToFixture, '.next-tf'),
          onData(data) {
            console.log(data.toString());
          },
          onError(data) {
            console.log(data.toString());
          },
        });
        await lambdaSAM.start();

        // Generate SAM for Proxy (Lambda@Edge)
        const proxyConfig = {
          routes: config.routes,
          staticRoutes: config.staticRoutes,
          lambdaRoutes: Object.values(config.lambdas).map(
            (lambda) => lambda.route
          ),
          prerenders: config.prerenders,
        };

        proxySAM = await generateProxySAM({
          pathToProxyPackage,
          proxyConfig: JSON.stringify(proxyConfig),
          onData(data) {
            console.log(data.toString());
          },
          onError(data) {
            console.log(data.toString());
          },
        });
        await proxySAM.start();
      });

      afterAll(async () => {
        // Shutdown SAM
        await lambdaSAM.stop();
        await proxySAM.stop();
      });

      test('Proxy', async () => {
        for (const probe of probeFile.probes) {
          const Request = await proxySAM.sendRequestEvent({
            uri: probe.path,
          });

          if ('origin' in Request) {
            // Request
            if (Request.origin?.custom) {
              // Request should be served by lambda (SSR)
              const basePath = Request.origin.custom.path;
              const { uri, querystring } = Request;

              // Merge request headers and custom headers from origin
              const headers = {
                ...normalizeCloudFrontHeaders(Request.headers),
                ...normalizeCloudFrontHeaders(
                  Request.origin.custom.customHeaders
                ),
              };
              const requestPath = `${basePath}${uri}${
                querystring !== '' ? `?${querystring}` : ''
              }`;

              const lambdaResponse = await lambdaSAM
                .sendApiGwRequest(requestPath, {
                  headers,
                })
                .then((res) => {
                  const headers = res.headers;

                  return res.text();
                })
                .then((text) => {
                  // If text is already JSON we dont need to parse base64
                  if (text.startsWith('{')) {
                    return text;
                  }

                  return Buffer.from(text, 'base64').toString('utf-8');
                });

              if (probe.mustContain) {
                expect(lambdaResponse).toContain(probe.mustContain);
              }
            } else if (Request.origin?.s3) {
              // Request should be served by static file system (S3)
              // Check static routes
              const { uri } = Request;
              if (!config.staticRoutes.find((route) => route === uri)) {
                fail(
                  `Could not resolve ${probe.path} to an existing lambda! (Resolved to: ${uri})`
                );
              } else {
                // TODO: Open the static file and check the content
              }
            } else {
              fail(`Path ${probe.path} returned invalid proxy request`);
            }
          } else {
            // Request-Response
            const Response = Request as CloudFrontResultResponse;

            if (probe.status) {
              expect(Response.status).toBe(probe.status.toString());
            }

            for (const header in probe.responseHeaders) {
              const lowerHeader = header.toLowerCase();
              expect(Response.headers![lowerHeader]).toBeDefined();
              expect(Response.headers![lowerHeader]).toContainEqual(
                expect.objectContaining({
                  value: probe.responseHeaders[header],
                })
              );
            }

            if (probe.statusDescription) {
              expect(Response.statusDescription).toBe(probe.statusDescription);
            }
          }
        }
      });
    });
  }
});
