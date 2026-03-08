const fs = require('fs');
const path = require('path');

class FlowCoverageReporter {
    constructor(options) {
        this.options = options || {};
        this.outputFile = this.options.outputFile || 'e2e-coverage.json';
        this.coverageData = {
            totalTests: 0,
            passedTests: 0,
            failedTests: 0,
            skippedTests: 0,
            flows: {},
            features: {}
        };
    }

    onTestEnd(test, result) {
        this.coverageData.totalTests++;
        if (result.status === 'passed') {
            this.coverageData.passedTests++;
        } else if (result.status === 'failed' || result.status === 'timedOut') {
            this.coverageData.failedTests++;
        } else {
            this.coverageData.skippedTests++;
        }

        // Extract tags like @flow:auth, @feature:add-expense from the full title path
        const titleAndTags = test.titlePath().join(' ') + ' ' + (test.tags ? test.tags.join(' ') : '');
        const flowMatches = titleAndTags.match(/@flow:([\w-]+)/g);
        const featureMatches = titleAndTags.match(/@feature:([\w-]+)/g);

        if (flowMatches) {
            // Use a Set to avoid double-counting if the tag appears in both describe and test title
            [...new Set(flowMatches)].forEach(tag => {
                const flowName = tag.replace('@flow:', '');
                if (!this.coverageData.flows[flowName]) {
                    this.coverageData.flows[flowName] = { passed: 0, failed: 0, total: 0 };
                }
                this.coverageData.flows[flowName].total++;
                if (result.status === 'passed') {
                    this.coverageData.flows[flowName].passed++;
                } else if (result.status === 'failed' || result.status === 'timedOut') {
                    this.coverageData.flows[flowName].failed++;
                }
            });
        }

        if (featureMatches) {
            [...new Set(featureMatches)].forEach(tag => {
                const featureName = tag.replace('@feature:', '');
                if (!this.coverageData.features[featureName]) {
                    this.coverageData.features[featureName] = { passed: 0, failed: 0, total: 0 };
                }
                this.coverageData.features[featureName].total++;
                if (result.status === 'passed') {
                    this.coverageData.features[featureName].passed++;
                } else if (result.status === 'failed' || result.status === 'timedOut') {
                    this.coverageData.features[featureName].failed++;
                }
            });
        }
    }

    async onEnd(result) {
        const outDir = path.dirname(this.outputFile);
        try {
            if (!fs.existsSync(outDir)) {
                fs.mkdirSync(outDir, { recursive: true });
            }

            fs.writeFileSync(
                this.outputFile,
                JSON.stringify(this.coverageData, null, 2)
            );
            console.log(`[Coverage Reporter] Flow coverage written to ${this.outputFile}`);
        } catch (e) {
            console.error(`[Coverage Reporter] Error writing flow coverage to ${this.outputFile}:`, e);
        }
    }
}

module.exports = FlowCoverageReporter;
