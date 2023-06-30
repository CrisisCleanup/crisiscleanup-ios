#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {
        float linearCorrect(float from, float to, float fraction) {
            float fromCorrected = pow(from, 2.2);
            float toCorrected = pow(to, 2.2);
            return fromCorrected + (toCorrected - fromCorrected) * fraction;
        };

        float4 lerpGrayscaleToColorKernel(sample_t s, float4 from, float4 to) {
            float alpha = s.a;
            if (alpha > 0) {
                float4 swappedColor;
                float fraction = s.r;
                swappedColor.r = linearCorrect(from.r, to.r, fraction);
                swappedColor.g = linearCorrect(from.g, to.g, fraction);
                swappedColor.b = linearCorrect(from.b, to.b, fraction);
                swappedColor.a = alpha;
                return swappedColor;
            }
            return s;
        }
    }
}
