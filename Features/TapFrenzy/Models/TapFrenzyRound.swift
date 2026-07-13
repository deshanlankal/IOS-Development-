import CoreGraphics

struct TapFrenzyRound {
    let roundLength = 10

    func buttonSize(for remainingTime: Int) -> CGFloat {
        let progress = CGFloat(remainingTime) / CGFloat(roundLength)
        return 86 + (progress * 164)
    }

    func isBonusBurstActive(remainingTime: Int) -> Bool {
        remainingTime == 5 || remainingTime == 4
    }
}
