import Foundation


class KMeansPoint {
  var x:Double = 0.0
  var y:Double = 0.0
    
  var label: String?
  
  init(x:Double,y:Double) {
    self.x = x
    self.y = y
  }
  
  func distanceTo(p:KMeansPoint) -> Double {
    return sqrt(pow(self.x - p.x, 2.0) + pow(self.y - p.y, 2.0));
  }
  
}


class KMeansGroup {
  var points = [KMeansPoint]()
  var candidateMean = KMeansPoint(x:0,y:0)
  
  func mean() -> KMeansPoint {
    var avgP = KMeansPoint(x: 0, y: 0);
    if self.points.count > 0 {
        avgP.x = self.points.map({$0.x as Double}).reduce(0, +) / Double(self.points.count)
        avgP.y = self.points.map({$0.y as Double}).reduce(0, +) / Double(self.points.count)
    }
    return avgP
  }
  
  func iterate() {
    self.candidateMean = self.mean()
    self.points = []
  }
  
  func sumSquaredErrors() -> Double {
    var s = self.points.map({ pow($0.distanceTo(p: self.candidateMean) as Double, 2)}).reduce(0, +)
    return s;
  }
  
  func candidateError() -> Double {
    return self.candidateMean.distanceTo(p: self.mean())
  }
}


class KMeansCluster {
  var groups = [KMeansGroup]()
  var points = [KMeansPoint]()
  var convergenceCriteria = 0.01
  var maxIterations = 1000
  
  func sumSquaredErrors() -> Double {
    return self.groups.map({$0.sumSquaredErrors()}).reduce(0, +)
  }
  
  func findMeans(count:Int) -> Int {
    var iterations = 0
    self.groups.removeAll(keepingCapacity: false)
    
    if self.points.count == 0 || count == 0 {
      return 0
    }
    if count > self.points.count {
      return 0
    }
    var initialCandidates = [KMeansPoint]()
    
    // to-do: 
    // find maximally distant points
    for i in 0...count-1 {
      var newGroup  = KMeansGroup()
      newGroup.candidateMean = self.points[i]
      self.groups.append(newGroup)
    }
    
    while iterations < maxIterations {
      for p in self.points {
        // which mean is closest?
        let closestMean = self.groups.sorted(by: {$0.candidateMean.distanceTo(p: p) < $1.candidateMean.distanceTo(p: p)}).first
        closestMean?.points.append(p)
      }
        let change = self.groups.map({$0.candidateError() as Double}).reduce(0, +)
      if change <= self.convergenceCriteria {
        break;
      }
      else {
        self.groups.map({$0.iterate()})
      }
        
      iterations += 1
    }
    return iterations
  }
  
  
  func findOptimalMeans(high:Int, tolerance:Double = 0.1) ->Int {
    
    if high <= 2 {
      return 0
    }
    if self.points.count == 0 {
      return 0
    }
    
    var pctChange = 0.0
    self.findMeans(count: 1)
    var prevSSE = self.sumSquaredErrors()
    var optimalMeans = 0
    
    for i in 2...high {
        let iter = self.findMeans(count: i)
      let thisSSE = self.sumSquaredErrors()
      pctChange = (prevSSE - thisSSE) / thisSSE
      prevSSE = thisSSE
      print("\(i) clusters: % change: \(pctChange)\n")
      if pctChange >= 0 && pctChange <= tolerance {
        optimalMeans = i
        break;
      }
    }
    return optimalMeans
  }

}
