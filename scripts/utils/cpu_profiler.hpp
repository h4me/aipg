#ifndef __CPU_PROFILER
#define __CPU_PROFILER

#define ENABLED_CPU_PROFILER

#ifdef ENABLED_CPU_PROFILER
#include <x86intrin.h>
#include <fstream>

#define _ORG__

#define INIT_PERF() static RtdscHelper rtdsc_helper
#define MAKE_PERF_VAR() unsigned long long perf = 0; (void) perf
#define BEGIN() perf = __rdtsc()

#ifdef _ORG_
#define END(name) rtdsc_helper.AddMeasurement(name, __rdtsc() - perf)
#else
#define END(name) rtdsc_helper.AddMeasurement( __rdtsc() - perf,name)
#endif

#define BEGIN_OVERALL() unsigned long long overall = __rdtsc()

#ifdef _ORG_
#define END_OVERALL() rtdsc_helper.AddMeasurement("Overall", __rdtsc() - overall)
#else
#define END_OVERALL() rtdsc_helper.AddMeasurement(  __rdtsc() - overall, "Overall")
#endif
class RtdscHelper
{
using uint64 = unsigned long long;
public:
#ifdef _ORG_  
  // void AddMeasurement(std::string name, uint64 time) {
  void AddMeasurement(const char* name, uint64 time) {
#else
//  void AddMeasurement(uint64 time,std::string name) {
  void AddMeasurement(uint64 time,const char* name) {
//  void AddMeasurement(uint64 time,const std::string& name) {
#endif    
    auto _pair = m_Measurements.emplace( name, decltype(m_Measurements)::mapped_type(time, 1) );

    if( ! _pair.second)
    {
        auto& none_const_pair =  (*(const_cast< decltype( _pair.first )* >( &_pair.first ) ))->second;
        none_const_pair.first += time;
        none_const_pair.second++;
    }

/*
    if(m_Measurements.find(name) != m_Measurements.end()) {
      m_Measurements[name].first += time;
      m_Measurements[name].second++;
    }
    else
      m_Measurements[name] = {time, 1};
*/
  }

  unsigned long long GetTsc() {
    auto process = [](std::string& line, unsigned long long *out_tsc) -> bool
    {
      if(line.find("model name") ==  std::string::npos )
        return false;

      // format is model name : <CPU model>
      // we want to extract CPU model only
      auto it = line.find(":");
      auto model_name = line.substr(it);
      std::cout << "MODEL: " << model_name << std::endl;
      it = line.find("@");
      float tsc_clock = stof(line.substr(it + 1))*1000000.0f;
      std::cout << "TSC: " << tsc_clock << std::endl;
      *out_tsc = tsc_clock;
      return true;
    };

    std::ifstream infile("/proc/cpuinfo");
    std::string line;
    bool run = true;
    unsigned long long result = 0;
    while (run && std::getline(infile, line))
    {
       run = !process(line, &result);
    }
    return result;
  }

  void PrintResults() {
    std::cout << "Convolution measurements" << std::endl;
    auto width = std::setw(20);
    std::cout << std::left << width << "Name"
                           << width << "Avg Time"
                           << width << "Ratio" << std::endl;
    auto overall_m = m_Measurements["Overall"];
    auto overall = overall_m.first / (double) overall_m.second;
    auto tsc = GetTsc();
    for(auto const& m : m_Measurements) {
      auto average = m.second.first / (double) m.second.second;
      std::cout << std::left << width << m.first
                             << width << average / tsc
                             << width << average / overall << std::endl;
    }
    std::cout << "------------------------" << std::endl;
  }

  ~RtdscHelper() {
    PrintResults();
  }
private:
  std::map<std::string, std::pair<uint64, unsigned>> m_Measurements; // name, time, count
};
#else
#define INIT_PERF()
#define MAKE_PERF_VAR()
#define BEGIN()
#define END(name)
#define BEGIN_OVERALL()
#define END_OVERALL()
#endif


#endif 
